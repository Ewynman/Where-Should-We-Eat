import asyncio
import logging
import random
import string
from contextlib import asynccontextmanager
from datetime import datetime, timezone

from bson.objectid import ObjectId
from fastapi import FastAPI, HTTPException, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from pymongo import MongoClient, ReturnDocument

from backend.schemas.rooms import (
    CreateRoomBody,
    JoinRoomBody,
    KickBody,
    StartVotingBody,
    TransferHostBody,
    VoteBody,
)
from backend.settings import Settings

settings = Settings()

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

mongo_details = {}

VOTE_DURATION_SECONDS = 60

KICKED_BY_HOST_MESSAGE = "You were removed from the room by the host."


# ---------------------------------------------------------------------------
# Connection Manager
# ---------------------------------------------------------------------------


class ConnectionManager:
    """
    Tracks WebSockets per room and optionally binds each socket to a username
    after a `join` message so the server can target users (kick) and run host
    failover when the host's socket disconnects.
    """

    def __init__(self):
        self.rooms: dict[str, set[WebSocket]] = {}
        self.user_sockets: dict[str, dict[str, set[WebSocket]]] = {}
        self.ws_meta: dict[WebSocket, tuple[str, str]] = {}

    async def connect(self, room_id: str, websocket: WebSocket):
        """Accept the connection and register it under the given room."""
        await websocket.accept()
        self.rooms.setdefault(room_id, set()).add(websocket)
        logger.info(
            "WS connected  room=%s  total=%d", room_id, len(self.rooms[room_id])
        )

    def bind(self, room_id: str, username: str, websocket: WebSocket) -> None:
        if not username:
            return
        self.user_sockets.setdefault(room_id, {}).setdefault(username, set()).add(
            websocket
        )
        self.ws_meta[websocket] = (room_id, username)

    def _unbind_socket(self, websocket: WebSocket) -> tuple[str, str] | None:
        meta = self.ws_meta.pop(websocket, None)
        if not meta:
            return None
        rid, username = meta
        users = self.user_sockets.get(rid, {})
        bucket = users.get(username)
        if bucket:
            bucket.discard(websocket)
            if not bucket:
                users.pop(username, None)
        if not users:
            self.user_sockets.pop(rid, None)
        return rid, username

    def disconnect(self, room_id: str, websocket: WebSocket) -> str | None:
        """
        Remove the connection. Returns the bound username (if any) so callers
        can schedule host failover.
        """
        meta = self._unbind_socket(websocket)
        username = meta[1] if meta else None
        room = self.rooms.get(room_id, set())
        room.discard(websocket)
        if not room:
            self.rooms.pop(room_id, None)
        logger.info("WS disconnected  room=%s  remaining=%d", room_id, len(room))
        return username

    async def broadcast(self, room_id: str, message: dict):
        """
        Send a JSON message to every connected client in a room.

        Dead connections are collected and removed so stale sockets don't
        accumulate.  We never raise inside this method - a single bad socket
        should not prevent the others from receiving the message.
        """
        dead: list[WebSocket] = []
        for ws in list(self.rooms.get(room_id, [])):
            try:
                await ws.send_json(message)
            except Exception:
                dead.append(ws)
        for ws in dead:
            self.disconnect(room_id, ws)

    async def send_to_user(self, room_id: str, username: str, message: dict) -> None:
        for ws in list(self.user_sockets.get(room_id, {}).get(username, [])):
            try:
                await ws.send_json(message)
            except Exception:
                self.disconnect(room_id, ws)

    async def close_user_connections(self, room_id: str, username: str) -> None:
        for ws in list(self.user_sockets.get(room_id, {}).get(username, [])):
            try:
                await ws.close()
            except Exception:
                pass
            self.disconnect(room_id, ws)

    async def maybe_promote_host_after_disconnect(
        self, room_id: str, disconnected_username: str | None
    ) -> None:
        """If the disconnected user was host, assign host to the first other participant."""
        if not disconnected_username:
            return
        room = mongo_details["rooms"].find_one({"_id": ObjectId(room_id)})
        if not room or room.get("hostId") != disconnected_username:
            return
        candidates = [
            p["username"]
            for p in room.get("participants", [])
            if p["username"] != disconnected_username
        ]
        if not candidates:
            return
        new_host = candidates[0]
        mongo_details["rooms"].update_one(
            {"_id": ObjectId(room_id)},
            {"$set": {"hostId": new_host}},
        )
        await self.broadcast(
            room_id,
            {"type": "host_changed", "hostId": new_host},
        )
        logger.info("Host promoted after WS disconnect  room=%s  host=%s", room_id, new_host)


manager = ConnectionManager()


# ---------------------------------------------------------------------------
# Timer helper
# ---------------------------------------------------------------------------


async def run_voting_timer(room_id: str, duration: int):
    """
    Background task that waits `duration` seconds, then:
      1. Reads the current vote tallies from MongoDB.
      2. Picks the winner (random tie-break).
      3. Updates the room status in MongoDB.
      4. Broadcasts a `voting_ended` event to every client still in the room.
    """
    await asyncio.sleep(duration)

    room = mongo_details["rooms"].find_one({"_id": ObjectId(room_id)})
    if not room or room.get("status") != "voting":
        return  # room was already closed or restarted

    options = room.get("options", [])
    winner = choose_winner(options)

    mongo_details["rooms"].update_one(
        {"_id": ObjectId(room_id)},
        {"$set": {"status": "finished", "winner": winner}},
    )

    await manager.broadcast(
        room_id,
        {
            "type": "voting_ended",
            "winner": winner,
            "options": options,
        },
    )
    logger.info("Voting ended  room=%s  winner=%s", room_id, winner)


# ---------------------------------------------------------------------------
# App setup
# ---------------------------------------------------------------------------


@asynccontextmanager
async def lifespan(app: FastAPI):
    mongo_details["client"] = MongoClient(settings.MONGO_URI)
    mongo_details["db"] = mongo_details["client"][settings.MONGO_DB]
    mongo_details["rooms"] = mongo_details["db"][settings.MONGO_ROOMS_COLLECTION]
    yield
    mongo_details["client"].close()


app = FastAPI(title="Where Should We Eat?", version="0.1.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ---------------------------------------------------------------------------
# Utility
# ---------------------------------------------------------------------------


def generate_room_code():
    return "".join(random.choices(string.ascii_uppercase, k=5))


def choose_winner(options: list[dict]) -> str | None:
    if not options:
        return None
    max_votes = max((o.get("votes", 0) for o in options), default=0)
    winners = [o for o in options if o.get("votes", 0) == max_votes]
    if not winners:
        return None
    return random.choice(winners).get("name")


async def maybe_finish_voting_early(room_id: str, room: dict) -> bool:
    participants = room.get("participants", [])
    voters = room.get("voters", [])
    if not participants or len(voters) < len(participants):
        return False

    options = room.get("options", [])
    winner = choose_winner(options)
    mongo_details["rooms"].update_one(
        {"_id": ObjectId(room_id)},
        {"$set": {"status": "finished", "winner": winner}},
    )
    await manager.broadcast(
        room_id,
        {
            "type": "voting_ended",
            "winner": winner,
            "options": options,
        },
    )
    logger.info("Voting ended early  room=%s  winner=%s", room_id, winner)
    return True


# ---------------------------------------------------------------------------
# HTTP Routes
# ---------------------------------------------------------------------------


@app.get("/")
def root():
    return {"message": "Where Should We Eat? API", "status": "ok"}


@app.get("/health")
def health():
    return {"status": "healthy"}


@app.get("/room/{room_id}", status_code=200)
async def get_room(room_id: str):
    room = mongo_details["rooms"].find_one({"_id": ObjectId(room_id)})
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")
    room["_id"] = str(room["_id"])
    return room


@app.post("/create-room", status_code=201)
async def create_room(body: CreateRoomBody):
    room_id = ObjectId()
    room_code = generate_room_code()

    # TODO: replace with real Google Places API call
    restaurants = [
        {"name": "Chipotle", "votes": 0},
        {"name": "Five Guys", "votes": 0},
        {"name": "Sushi Palace", "votes": 0},
        {"name": "Taco Bell", "votes": 0},
    ]

    new_room = {
        "_id": room_id,
        "code": room_code,
        "hostId": body.host_name,
        "maxCapacity": body.max_capacity,
        "status": "waiting",  # waiting → voting → finished
        "endTime": None,
        "winner": None,
        "options": restaurants,
        "participants": [{"username": body.host_name}],
        "voters": [],  # tracks who has already voted
    }
    mongo_details["rooms"].insert_one(new_room)
    return {"room_id": str(room_id), "code": room_code, "restaurants": restaurants}


@app.post("/join-room", status_code=200)
async def join_room(body: JoinRoomBody):
    code_upper = body.code.strip().upper()
    room = mongo_details["rooms"].find_one({"code": code_upper})
    if room is None and body.room_id:
        try:
            room = mongo_details["rooms"].find_one({"_id": ObjectId(body.room_id)})
        except Exception:
            room = None
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")
    if room["code"] != code_upper:
        raise HTTPException(status_code=403, detail="Invalid room code")
    if room["status"] != "waiting":
        raise HTTPException(status_code=400, detail="Voting has already started")

    oid = room["_id"]
    updated = mongo_details["rooms"].find_one_and_update(
        {
            "_id": oid,
            "code": code_upper,
            "status": "waiting",
            "participants": {"$not": {"$elemMatch": {"username": body.username}}},
            "$expr": {
                "$lt": [
                    {"$size": "$participants"},
                    {"$ifNull": ["$maxCapacity", 20]},
                ]
            },
        },
        {"$push": {"participants": {"username": body.username}}},
        return_document=ReturnDocument.AFTER,
    )

    if updated is not None:
        rid = str(updated["_id"])
        await manager.broadcast(
            rid,
            {
                "type": "participants_updated",
                "participants": updated["participants"],
                "hostId": updated["hostId"],
            },
        )
        return {
            "room_id": rid,
            "code": updated["code"],
            "restaurants": updated["options"],
            "participants": updated["participants"],
        }

    cur = mongo_details["rooms"].find_one({"_id": oid})
    if not cur:
        raise HTTPException(status_code=404, detail="Room not found")
    if cur["code"] != code_upper:
        raise HTTPException(status_code=403, detail="Invalid room code")
    if cur["status"] != "waiting":
        raise HTTPException(status_code=400, detail="Voting has already started")
    if body.username in {u["username"] for u in cur["participants"]}:
        raise HTTPException(
            status_code=400, detail="Username already taken in this room"
        )
    cap = cur.get("maxCapacity", 20)
    if len(cur["participants"]) >= cap:
        raise HTTPException(status_code=400, detail="Room is full")
    raise HTTPException(status_code=400, detail="Could not join room")


@app.post("/api/rooms/{room_id}/start", status_code=200)
async def start_room_voting(room_id: str, body: StartVotingBody):
    room = mongo_details["rooms"].find_one({"_id": ObjectId(room_id)})
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")
    if room["hostId"] != body.userId:
        raise HTTPException(status_code=403, detail="Only the host can start voting")
    if room["status"] != "waiting":
        raise HTTPException(status_code=400, detail="Voting already started")

    end_time = datetime.now(timezone.utc).timestamp() + body.durationSeconds
    end_time_iso = datetime.fromtimestamp(end_time, tz=timezone.utc).isoformat()

    mongo_details["rooms"].update_one(
        {"_id": ObjectId(room_id)},
        {"$set": {"status": "voting", "endTime": end_time_iso}},
    )

    await manager.broadcast(
        room_id,
        {
            "type": "voting_started",
            "end_time": end_time_iso,
            "options": room["options"],
        },
    )

    asyncio.create_task(run_voting_timer(room_id, body.durationSeconds))
    return {"status": "ok", "end_time": end_time_iso}


@app.post("/api/rooms/{room_id}/vote", status_code=200)
async def vote_room_option(room_id: str, body: VoteBody):
    room = mongo_details["rooms"].find_one({"_id": ObjectId(room_id)})
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")
    if room.get("status") != "voting":
        raise HTTPException(status_code=400, detail="Voting is not active")

    username = body.userId
    if username in room.get("voters", []):
        raise HTTPException(status_code=400, detail="You have already voted")

    # Frontend currently sends optionId; in this backend options don't have IDs,
    # so optionId is treated as option name.
    option_name = body.optionId
    result = mongo_details["rooms"].update_one(
        {
            "_id": ObjectId(room_id),
            "options.name": option_name,
            "voters": {"$ne": username},
        },
        {
            "$inc": {"options.$.votes": 1},
            "$push": {"voters": username},
        },
    )
    if result.modified_count == 0:
        raise HTTPException(status_code=400, detail="Vote could not be recorded")

    updated_room = mongo_details["rooms"].find_one({"_id": ObjectId(room_id)})
    if not updated_room:
        raise HTTPException(status_code=404, detail="Room not found")
    await manager.broadcast(
        room_id,
        {
            "type": "vote_update",
            "options": updated_room["options"],
        },
    )
    ended = await maybe_finish_voting_early(room_id, updated_room)
    return {"status": "ok", "ended": ended}


@app.post("/api/rooms/{room_id}/kick", status_code=200)
async def kick_room_participant(room_id: str, body: KickBody):
    room = mongo_details["rooms"].find_one({"_id": ObjectId(room_id)})
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")
    if room["hostId"] != body.userId:
        raise HTTPException(status_code=403, detail="Only the host can remove participants")
    if body.targetUsername == body.userId:
        raise HTTPException(status_code=400, detail="You cannot remove yourself from the room")
    usernames = {p["username"] for p in room.get("participants", [])}
    if body.targetUsername not in usernames:
        raise HTTPException(status_code=400, detail="User is not in this room")

    mongo_details["rooms"].update_one(
        {"_id": ObjectId(room_id)},
        {
            "$pull": {
                "participants": {"username": body.targetUsername},
                "voters": body.targetUsername,
            }
        },
    )

    await manager.send_to_user(
        room_id,
        body.targetUsername,
        {
            "type": "kicked_by_host",
            "message": KICKED_BY_HOST_MESSAGE,
        },
    )
    await manager.close_user_connections(room_id, body.targetUsername)

    updated = mongo_details["rooms"].find_one({"_id": ObjectId(room_id)})
    if not updated:
        raise HTTPException(status_code=404, detail="Room not found")
    await manager.broadcast(
        room_id,
        {
            "type": "participants_updated",
            "participants": updated["participants"],
            "hostId": updated["hostId"],
        },
    )
    return {"status": "ok"}


@app.post("/api/rooms/{room_id}/transfer-host", status_code=200)
async def transfer_room_host(room_id: str, body: TransferHostBody):
    room = mongo_details["rooms"].find_one({"_id": ObjectId(room_id)})
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")
    if room["hostId"] != body.userId:
        raise HTTPException(status_code=403, detail="Only the host can transfer host privileges")
    usernames = {p["username"] for p in room.get("participants", [])}
    if body.newHostUsername not in usernames:
        raise HTTPException(
            status_code=400, detail="New host must be an active participant in the room"
        )
    if body.newHostUsername == room["hostId"]:
        raise HTTPException(status_code=400, detail="That user is already the host")

    mongo_details["rooms"].update_one(
        {"_id": ObjectId(room_id)},
        {"$set": {"hostId": body.newHostUsername}},
    )
    updated = mongo_details["rooms"].find_one({"_id": ObjectId(room_id)})
    if not updated:
        raise HTTPException(status_code=404, detail="Room not found")
    await manager.broadcast(
        room_id,
        {
            "type": "host_changed",
            "hostId": updated["hostId"],
            "participants": updated["participants"],
        },
    )
    return {"status": "ok", "hostId": updated["hostId"]}


# ---------------------------------------------------------------------------
# WebSocket Route
# ---------------------------------------------------------------------------


@app.websocket("/ws/{room_id}")
async def websocket_endpoint(websocket: WebSocket, room_id: str):
    """
    Persistent connection for a single client in a room.

    Expected inbound message shapes
    ────────────────────────────────
    { "type": "join",  "username": "Alice" }
        → broadcasts updated participant list to everyone in the room.

    { "type": "start_voting", "username": "Alice" }
        → host-only action; transitions room to "voting", starts the 60-second
          timer, and broadcasts voting_started with end_time to all clients.

    { "type": "vote", "username": "Alice", "restaurant": "Chipotle" }
        → records Alice's vote (one per user), updates MongoDB, and broadcasts
          updated tallies to all clients.

    Outbound broadcast message shapes
    ────────────────────────────────────
    { "type": "user_joined",    "participants": [...] }
    { "type": "voting_started", "end_time": <ISO-8601 UTC string>, "options": [...] }
    { "type": "vote_update",    "options": [...] }
    { "type": "voting_ended",   "winner": "Chipotle", "options": [...] }
    { "type": "error",          "message": "..." }   ← sent only to the sender
    """

    await manager.connect(room_id, websocket)

    try:
        while True:
            data = await websocket.receive_json()
            msg_type = data.get("type")
            username = data.get("username", "")

            # ── JOIN ────────────────────────────────────────────────────────
            if msg_type == "join":
                if not username:
                    await websocket.send_json(
                        {"type": "error", "message": "Missing username"}
                    )
                    continue
                room = mongo_details["rooms"].find_one({"_id": ObjectId(room_id)})
                if not room:
                    await websocket.send_json(
                        {"type": "error", "message": "Room not found"}
                    )
                    continue
                allowed = {p["username"] for p in room.get("participants", [])}
                if username not in allowed:
                    await websocket.send_json(
                        {"type": "error", "message": "Not a participant in this room"}
                    )
                    continue

                manager.bind(room_id, username, websocket)
                await manager.broadcast(
                    room_id,
                    {
                        "type": "participants_updated",
                        "participants": room["participants"],
                        "hostId": room["hostId"],
                    },
                )

            # ── START VOTING ────────────────────────────────────────────────
            elif msg_type == "start_voting":
                room = mongo_details["rooms"].find_one({"_id": ObjectId(room_id)})
                if not room:
                    await websocket.send_json(
                        {"type": "error", "message": "Room not found"}
                    )
                    continue
                if room["hostId"] != username:
                    await websocket.send_json(
                        {"type": "error", "message": "Only the host can start voting"}
                    )
                    continue
                if room["status"] != "waiting":
                    await websocket.send_json(
                        {"type": "error", "message": "Voting already started"}
                    )
                    continue

                end_time = (
                    datetime.now(timezone.utc).timestamp() + VOTE_DURATION_SECONDS
                )
                end_time_iso = datetime.fromtimestamp(
                    end_time, tz=timezone.utc
                ).isoformat()

                mongo_details["rooms"].update_one(
                    {"_id": ObjectId(room_id)},
                    {"$set": {"status": "voting", "endTime": end_time_iso}},
                )

                await manager.broadcast(
                    room_id,
                    {
                        "type": "voting_started",
                        "end_time": end_time_iso,
                        "options": room["options"],
                    },
                )

                # Fire-and-forget timer — runs concurrently without blocking
                # any other messages.
                asyncio.create_task(run_voting_timer(room_id, VOTE_DURATION_SECONDS))

            # ── VOTE ────────────────────────────────────────────────────────
            elif msg_type == "vote":
                restaurant_name = data.get("restaurant")
                if not restaurant_name:
                    await websocket.send_json(
                        {"type": "error", "message": "Missing restaurant field"}
                    )
                    continue

                room = mongo_details["rooms"].find_one({"_id": ObjectId(room_id)})
                if not room:
                    await websocket.send_json(
                        {"type": "error", "message": "Room not found"}
                    )
                    continue
                if room["status"] != "voting":
                    await websocket.send_json(
                        {"type": "error", "message": "Voting is not active"}
                    )
                    continue
                if username in room.get("voters", []):
                    await websocket.send_json(
                        {"type": "error", "message": "You have already voted"}
                    )
                    continue

                # Atomically increment the vote and record the voter.
                result = mongo_details["rooms"].update_one(
                    {
                        "_id": ObjectId(room_id),
                        "options.name": restaurant_name,
                        "voters": {"$ne": username},  # extra guard against duplicates
                    },
                    {
                        "$inc": {"options.$.votes": 1},
                        "$push": {"voters": username},
                    },
                )
                if result.modified_count == 0:
                    await websocket.send_json(
                        {"type": "error", "message": "Vote could not be recorded"}
                    )
                    continue

                updated_room = mongo_details["rooms"].find_one(
                    {"_id": ObjectId(room_id)}
                )
                if not updated_room:
                    await websocket.send_json(
                        {"type": "error", "message": "Room not found"}
                    )
                    continue
                await manager.broadcast(
                    room_id,
                    {
                        "type": "vote_update",
                        "options": updated_room["options"],
                    },
                )
                await maybe_finish_voting_early(room_id, updated_room)

            # ── Restart (Optional) ──────────────────────────────────────────
            # TODO : complete this


            else:
                await websocket.send_json(
                    {"type": "error", "message": f"Unknown message type: {msg_type}"}
                )


    except WebSocketDisconnect:
        uname = manager.disconnect(room_id, websocket)
        asyncio.create_task(
            manager.maybe_promote_host_after_disconnect(room_id, uname)
        )
        logger.info("Client disconnected cleanly  room=%s", room_id)
    except Exception as e:
        logger.exception("Unexpected WS error  room=%s", room_id)
        uname = manager.disconnect(room_id, websocket)
        asyncio.create_task(
            manager.maybe_promote_host_after_disconnect(room_id, uname)
        )
