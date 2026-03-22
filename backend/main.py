import asyncio
import logging
import random
import string
from contextlib import asynccontextmanager
from datetime import datetime, timezone

from bson.objectid import ObjectId
from fastapi import FastAPI, HTTPException, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from pymongo import MongoClient

from schemas.rooms import CreateRoomBody, JoinRoomBody
from settings import Settings

settings = Settings()

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

mongo_details = {}

VOTE_DURATION_SECONDS = 60


# ---------------------------------------------------------------------------
# Connection Manager
# ---------------------------------------------------------------------------


class ConnectionManager:
    """
    Tracks active WebSocket connections grouped by room_id.

    Structure:
        self.rooms = {
            "room_id_abc": {websocket_1, websocket_2, ...},
            "room_id_xyz": {websocket_3, ...},
        }

    """

    def __init__(self):
        self.rooms: dict[str, set[WebSocket]] = {}

    async def connect(self, room_id: str, websocket: WebSocket):
        """Accept the connection and register it under the given room."""
        await websocket.accept()
        self.rooms.setdefault(room_id, set()).add(websocket)
        logger.info(
            "WS connected  room=%s  total=%d", room_id, len(self.rooms[room_id])
        )

    def disconnect(self, room_id: str, websocket: WebSocket):
        """Remove the connection.  Cleans up the room entry if it becomes empty."""
        room = self.rooms.get(room_id, set())
        room.discard(websocket)
        if not room:
            self.rooms.pop(room_id, None)
        logger.info("WS disconnected  room=%s  remaining=%d", room_id, len(room))

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
    max_votes = max((o["votes"] for o in options), default=0)
    winners = [o for o in options if o["votes"] == max_votes]
    winner = random.choice(winners)["name"]

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
def join_room(body: JoinRoomBody):
    room = mongo_details["rooms"].find_one({"_id": ObjectId(body.room_id)})
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")
    if room["code"] != body.code:
        raise HTTPException(status_code=403, detail="Invalid room code")
    if room["status"] != "waiting":
        raise HTTPException(status_code=400, detail="Voting has already started")

    registered = [u["username"] for u in room["participants"]]
    if body.username in registered:
        raise HTTPException(
            status_code=400, detail="Username already taken in this room"
        )

    mongo_details["rooms"].update_one(
        {"_id": ObjectId(body.room_id)},
        {"$push": {"participants": {"username": body.username}}},
    )
    return {
        "room_id": body.room_id,
        "code": room["code"],
        "restaurants": room["options"],
        "participants": room["participants"] + [{"username": body.username}],
    }


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
                room = mongo_details["rooms"].find_one({"_id": ObjectId(room_id)})
                if not room:
                    await websocket.send_json(
                        {"type": "error", "message": "Room not found"}
                    )
                    continue

                await manager.broadcast(
                    room_id,
                    {
                        "type": "user_joined",
                        "participants": room["participants"],
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
                await manager.broadcast(
                    room_id,
                    {
                        "type": "vote_update",
                        "options": updated_room["options"],
                    },
                )

            # ── Restart (Optional) ──────────────────────────────────────────
            # TODO : complete this


            else:
                await websocket.send_json(
                    {"type": "error", "message": f"Unknown message type: {msg_type}"}
                )


    except WebSocketDisconnect:
        manager.disconnect(room_id, websocket)
        logger.info("Client disconnected cleanly  room=%s", room_id)
    except Exception as e:
        logger.exception("Unexpected WS error  room=%s", room_id)
        manager.disconnect(room_id, websocket)
