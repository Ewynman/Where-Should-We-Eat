import asyncio
import logging
import random
import string
from contextlib import asynccontextmanager
from datetime import datetime, timezone

from bson.objectid import ObjectId
import httpx
from fastapi import FastAPI, HTTPException, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import Response
from pymongo import MongoClient, ReturnDocument

from backend.schemas.rooms import (
    AddOptionBody,
    CreateRoomBody,
    JoinRoomBody,
    KickBody,
    RestartBody,
    StartVotingBody,
    TransferHostBody,
    VoteBody,
)
from backend.services.places_service import (
    PLACES_BASE,
    fetch_restaurant_options_for_cuisines,
)
from backend.settings import Settings

settings = Settings()

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

mongo_details: dict = {}

VOTE_DURATION_SECONDS = 60

STATUS_WAITING = "waiting"
STATUS_CUISINE_VOTING = "cuisine_voting"
STATUS_FETCHING = "fetching_restaurants"
STATUS_RESTAURANT_VOTING = "restaurant_voting"
STATUS_FINISHED = "finished"

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
        meta = self._unbind_socket(websocket)
        username = meta[1] if meta else None
        room = self.rooms.get(room_id, set())
        room.discard(websocket)
        if not room:
            self.rooms.pop(room_id, None)
        logger.info("WS disconnected  room=%s  remaining=%d", room_id, len(room))
        return username

    async def broadcast(self, room_id: str, message: dict):
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
# Voting / phase helpers
# ---------------------------------------------------------------------------


def choose_winner(options: list[dict]) -> str | None:
    if not options:
        return None
    max_votes = max((o.get("votes", 0) for o in options), default=0)
    winners = [o for o in options if o.get("votes", 0) == max_votes]
    if not winners:
        return None
    return random.choice(winners).get("name")


def select_top_four_cuisine_labels(options: list[dict]) -> list[str]:
    """Rank by votes (desc), random tie-break within same vote count; up to 4 labels."""
    if not options:
        return []
    by_votes: dict[int, list[dict]] = {}
    for o in options:
        v = int(o.get("votes", 0) or 0)
        by_votes.setdefault(v, []).append(o)
    ordered: list[dict] = []
    for v in sorted(by_votes.keys(), reverse=True):
        bucket = by_votes[v]
        random.shuffle(bucket)
        ordered.extend(bucket)
    top = ordered[:4]
    labels: list[str] = []
    for o in top:
        label = (o.get("cuisineType") or o.get("name") or "").strip()
        if label:
            labels.append(label)
    return labels


async def cuisine_voting_timer(room_id: str, duration: int) -> None:
    await asyncio.sleep(duration)
    room = mongo_details["rooms"].find_one({"_id": ObjectId(room_id)})
    if not room or room.get("status") != STATUS_CUISINE_VOTING:
        return
    await finalize_cuisine_voting_and_start_fetch(room_id)


async def finalize_cuisine_voting_and_start_fetch(room_id: str) -> None:
    updated = mongo_details["rooms"].find_one_and_update(
        {"_id": ObjectId(room_id), "status": STATUS_CUISINE_VOTING},
        {"$set": {"status": STATUS_FETCHING, "voters": []}},
        return_document=ReturnDocument.AFTER,
    )
    if not updated:
        return

    labels = select_top_four_cuisine_labels(updated.get("options", []))
    lat = updated.get("hostLatitude")
    lng = updated.get("hostLongitude")
    duration = int(updated.get("voteDurationSeconds") or VOTE_DURATION_SECONDS)

    await manager.broadcast(room_id, {"type": "fetching_started"})
    asyncio.create_task(
        run_places_fetch_job(room_id, labels, lat, lng, duration)
    )
    logger.info(
        "Cuisine voting ended  room=%s  top_cuisines=%s",
        room_id,
        labels,
    )


async def run_places_fetch_job(
    room_id: str,
    labels: list[str],
    lat: float | None,
    lng: float | None,
    duration_seconds: int,
) -> None:
    if lat is None or lng is None:
        mongo_details["rooms"].update_one(
            {"_id": ObjectId(room_id), "status": STATUS_FETCHING},
            {
                "$set": {
                    "status": STATUS_WAITING,
                    "placesError": "Missing host location for restaurant search.",
                    "voters": [],
                }
            },
        )
        await manager.broadcast(room_id, {"type": "fetching_failed"})
        return

    key = settings.google_places_key
    opts, err = await fetch_restaurant_options_for_cuisines(
        key, labels, float(lat), float(lng)
    )
    if err or not opts:
        mongo_details["rooms"].update_one(
            {"_id": ObjectId(room_id), "status": STATUS_FETCHING},
            {
                "$set": {
                    "status": STATUS_WAITING,
                    "placesError": err or "No restaurants found.",
                    "voters": [],
                }
            },
        )
        await manager.broadcast(room_id, {"type": "fetching_failed"})
        return

    for o in opts:
        o["id"] = str(ObjectId())

    end_time = datetime.now(timezone.utc).timestamp() + duration_seconds
    end_time_iso = datetime.fromtimestamp(end_time, tz=timezone.utc).isoformat()

    mongo_details["rooms"].update_one(
        {"_id": ObjectId(room_id), "status": STATUS_FETCHING},
        {
            "$set": {
                "status": STATUS_RESTAURANT_VOTING,
                "options": opts,
                "voters": [],
                "endTime": end_time_iso,
                "placesError": None,
            }
        },
    )
    refreshed = mongo_details["rooms"].find_one({"_id": ObjectId(room_id)})
    await manager.broadcast(
        room_id,
        {
            "type": "voting_started",
            "end_time": end_time_iso,
            "options": refreshed.get("options", []) if refreshed else opts,
        },
    )
    asyncio.create_task(restaurant_voting_timer(room_id, duration_seconds))
    logger.info("Restaurant voting started  room=%s  options=%d", room_id, len(opts))


async def restaurant_voting_timer(room_id: str, duration: int) -> None:
    await asyncio.sleep(duration)
    room = mongo_details["rooms"].find_one({"_id": ObjectId(room_id)})
    if not room or room.get("status") != STATUS_RESTAURANT_VOTING:
        return
    options = room.get("options", [])
    winner = choose_winner(options)
    mongo_details["rooms"].update_one(
        {"_id": ObjectId(room_id)},
        {"$set": {"status": STATUS_FINISHED, "winner": winner}},
    )
    await manager.broadcast(
        room_id,
        {
            "type": "voting_ended",
            "winner": winner,
            "options": options,
        },
    )
    logger.info("Restaurant voting ended  room=%s  winner=%s", room_id, winner)


async def maybe_finish_cuisine_voting_early(room_id: str, room: dict) -> bool:
    if room.get("status") != STATUS_CUISINE_VOTING:
        return False
    participants = room.get("participants", [])
    voters = room.get("voters", [])
    if not participants or len(voters) < len(participants):
        return False
    await finalize_cuisine_voting_and_start_fetch(room_id)
    return True


async def maybe_finish_restaurant_voting_early(room_id: str, room: dict) -> bool:
    if room.get("status") != STATUS_RESTAURANT_VOTING:
        return False
    participants = room.get("participants", [])
    voters = room.get("voters", [])
    if not participants or len(voters) < len(participants):
        return False
    options = room.get("options", [])
    winner = choose_winner(options)
    mongo_details["rooms"].update_one(
        {"_id": ObjectId(room_id)},
        {"$set": {"status": STATUS_FINISHED, "winner": winner}},
    )
    await manager.broadcast(
        room_id,
        {
            "type": "voting_ended",
            "winner": winner,
            "options": options,
        },
    )
    logger.info("Restaurant voting ended early  room=%s  winner=%s", room_id, winner)
    return True


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
# HTTP Routes
# ---------------------------------------------------------------------------


@app.get("/")
def root():
    return {"message": "Where Should We Eat? API", "status": "ok"}


@app.get("/health")
def health():
    return {"status": "healthy"}


@app.get("/api/place-photo", response_class=Response)
async def proxy_place_photo(photoName: str, maxPx: int = 800):
    """Stream a Google Places photo without exposing the API key in the app."""
    key = settings.google_places_key
    if not key or not photoName.strip() or ".." in photoName:
        raise HTTPException(status_code=400, detail="Invalid photo request")
    px = max(120, min(int(maxPx), 1600))
    url = f"{PLACES_BASE}/{photoName}/media?maxHeightPx={px}&maxWidthPx={px}&key={key}"
    async with httpx.AsyncClient(timeout=30.0) as client:
        r = await client.get(url, follow_redirects=True)
    if r.status_code != 200:
        raise HTTPException(status_code=404, detail="Photo not available")
    ct = r.headers.get("content-type", "image/jpeg")
    return Response(content=r.content, media_type=ct)


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

    new_room = {
        "_id": room_id,
        "code": room_code,
        "hostId": body.host_name,
        "maxCapacity": body.max_capacity,
        "status": STATUS_WAITING,
        "endTime": None,
        "winner": None,
        "options": [],
        "participants": [{"username": body.host_name}],
        "voters": [],
        "hostLatitude": body.latitude,
        "hostLongitude": body.longitude,
        "placesError": None,
        "voteDurationSeconds": None,
    }
    mongo_details["rooms"].insert_one(new_room)
    return {
        "room_id": str(room_id),
        "code": room_code,
        "restaurants": [],
    }


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
    if room["status"] != STATUS_WAITING:
        raise HTTPException(status_code=400, detail="Voting has already started")

    oid = room["_id"]
    updated = mongo_details["rooms"].find_one_and_update(
        {
            "_id": oid,
            "code": code_upper,
            "status": STATUS_WAITING,
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
            "options": updated["options"],
            "participants": updated["participants"],
            "hostId": updated["hostId"],
            "maxCapacity": updated.get("maxCapacity", 20),
            "status": updated.get("status", STATUS_WAITING),
        }

    cur = mongo_details["rooms"].find_one({"_id": oid})
    if not cur:
        raise HTTPException(status_code=404, detail="Room not found")
    if cur["code"] != code_upper:
        raise HTTPException(status_code=403, detail="Invalid room code")
    if cur["status"] != STATUS_WAITING:
        raise HTTPException(status_code=400, detail="Voting has already started")
    if body.username in {u["username"] for u in cur["participants"]}:
        raise HTTPException(
            status_code=400, detail="Username already taken in this room"
        )
    cap = cur.get("maxCapacity", 20)
    if len(cur["participants"]) >= cap:
        raise HTTPException(status_code=400, detail="Room is full")
    raise HTTPException(status_code=400, detail="Could not join room")


@app.post("/api/rooms/{room_id}/options", status_code=200)
async def add_room_option(room_id: str, body: AddOptionBody):
    room = mongo_details["rooms"].find_one({"_id": ObjectId(room_id)})
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")
    if room.get("status") != STATUS_WAITING:
        raise HTTPException(status_code=400, detail="Suggestions are only allowed before voting")
    usernames = {p["username"] for p in room.get("participants", [])}
    if body.userId not in usernames:
        raise HTTPException(status_code=403, detail="You are not in this room")

    options = room.get("options", [])
    if len(options) >= 10:
        raise HTTPException(status_code=400, detail="Maximum 10 suggestions reached")

    new_option = {
        "id": str(ObjectId()),
        "name": body.name.strip(),
        "votes": 0,
        "source": "cuisine",
        "cuisineType": body.cuisineType.strip(),
    }
    if not new_option["name"]:
        raise HTTPException(status_code=400, detail="Name is required")

    result = mongo_details["rooms"].update_one(
        {
            "_id": ObjectId(room_id),
            "status": STATUS_WAITING,
            "$expr": {"$lt": [{"$size": {"$ifNull": ["$options", []]}}, 10]},
        },
        {"$push": {"options": new_option}, "$set": {"placesError": None}},
    )
    if result.modified_count == 0:
        raise HTTPException(status_code=400, detail="Could not add suggestion")

    updated = mongo_details["rooms"].find_one({"_id": ObjectId(room_id)})
    await manager.broadcast(
        room_id,
        {"type": "vote_update", "options": updated.get("options", [])},
    )
    return {"status": "ok"}


@app.post("/api/rooms/{room_id}/start", status_code=200)
async def start_room_voting(room_id: str, body: StartVotingBody):
    room = mongo_details["rooms"].find_one({"_id": ObjectId(room_id)})
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")
    if room["hostId"] != body.userId:
        raise HTTPException(status_code=403, detail="Only the host can start voting")
    if room["status"] != STATUS_WAITING:
        raise HTTPException(status_code=400, detail="Voting already started")

    duration = max(10, min(int(body.durationSeconds), 3600))
    end_time = datetime.now(timezone.utc).timestamp() + duration
    end_time_iso = datetime.fromtimestamp(end_time, tz=timezone.utc).isoformat()

    mongo_details["rooms"].update_one(
        {"_id": ObjectId(room_id)},
        {
            "$set": {
                "status": STATUS_CUISINE_VOTING,
                "endTime": end_time_iso,
                "voters": [],
                "hostLatitude": body.latitude,
                "hostLongitude": body.longitude,
                "voteDurationSeconds": duration,
                "placesError": None,
            }
        },
    )
    refreshed = mongo_details["rooms"].find_one({"_id": ObjectId(room_id)})
    await manager.broadcast(
        room_id,
        {
            "type": "voting_started",
            "end_time": end_time_iso,
            "options": refreshed.get("options", []) if refreshed else [],
        },
    )

    asyncio.create_task(cuisine_voting_timer(room_id, duration))
    return {"status": "ok", "end_time": end_time_iso}


@app.post("/api/rooms/{room_id}/vote", status_code=200)
async def vote_room_option(room_id: str, body: VoteBody):
    room = mongo_details["rooms"].find_one({"_id": ObjectId(room_id)})
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")
    status = room.get("status")
    if status not in (STATUS_CUISINE_VOTING, STATUS_RESTAURANT_VOTING):
        raise HTTPException(status_code=400, detail="Voting is not active")

    username = body.userId
    if username in room.get("voters", []):
        raise HTTPException(status_code=400, detail="You have already voted")

    usernames = {p["username"] for p in room.get("participants", [])}
    if username not in usernames:
        raise HTTPException(status_code=403, detail="You are not in this room")

    option_id = body.optionId
    result = mongo_details["rooms"].update_one(
        {
            "_id": ObjectId(room_id),
            "options.id": option_id,
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

    ended = False
    if updated_room.get("status") == STATUS_CUISINE_VOTING:
        await maybe_finish_cuisine_voting_early(room_id, updated_room)
    elif updated_room.get("status") == STATUS_RESTAURANT_VOTING:
        ended = await maybe_finish_restaurant_voting_early(room_id, updated_room)

    return {"status": "ok", "ended": ended}


@app.post("/api/rooms/{room_id}/restart", status_code=200)
async def restart_room(room_id: str, body: RestartBody):
    room = mongo_details["rooms"].find_one({"_id": ObjectId(room_id)})
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")
    if room["hostId"] != body.userId:
        raise HTTPException(status_code=403, detail="Only the host can restart the session")

    mongo_details["rooms"].update_one(
        {"_id": ObjectId(room_id)},
        {
            "$set": {
                "status": STATUS_WAITING,
                "options": [],
                "voters": [],
                "winner": None,
                "endTime": None,
                "placesError": None,
                "voteDurationSeconds": None,
            }
        },
    )
    updated = mongo_details["rooms"].find_one({"_id": ObjectId(room_id)})
    if not updated:
        raise HTTPException(status_code=404, detail="Room not found")
    updated["_id"] = str(updated["_id"])
    return updated


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


def generate_room_code():
    return "".join(random.choices(string.ascii_uppercase, k=5))


# ---------------------------------------------------------------------------
# WebSocket Route
# ---------------------------------------------------------------------------


@app.websocket("/ws/{room_id}")
async def websocket_endpoint(websocket: WebSocket, room_id: str):
    await manager.connect(room_id, websocket)

    try:
        while True:
            data = await websocket.receive_json()
            msg_type = data.get("type")
            username = data.get("username", "")

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
                if room["status"] != STATUS_WAITING:
                    await websocket.send_json(
                        {"type": "error", "message": "Voting already started"}
                    )
                    continue

                lat = room.get("hostLatitude")
                lng = room.get("hostLongitude")
                if lat is None or lng is None:
                    await websocket.send_json(
                        {
                            "type": "error",
                            "message": "Host location missing; start voting from the app (HTTP) instead.",
                        }
                    )
                    continue

                duration = int(room.get("voteDurationSeconds") or VOTE_DURATION_SECONDS)
                end_time = (
                    datetime.now(timezone.utc).timestamp() + duration
                )
                end_time_iso = datetime.fromtimestamp(
                    end_time, tz=timezone.utc
                ).isoformat()

                mongo_details["rooms"].update_one(
                    {"_id": ObjectId(room_id)},
                    {
                        "$set": {
                            "status": STATUS_CUISINE_VOTING,
                            "endTime": end_time_iso,
                            "voters": [],
                            "voteDurationSeconds": duration,
                            "placesError": None,
                        }
                    },
                )
                refreshed = mongo_details["rooms"].find_one(
                    {"_id": ObjectId(room_id)}
                )
                await manager.broadcast(
                    room_id,
                    {
                        "type": "voting_started",
                        "end_time": end_time_iso,
                        "options": refreshed.get("options", []) if refreshed else [],
                    },
                )
                asyncio.create_task(cuisine_voting_timer(room_id, duration))

            elif msg_type == "vote":
                option_key = data.get("optionId") or data.get("restaurant")
                if not option_key:
                    await websocket.send_json(
                        {"type": "error", "message": "Missing optionId or restaurant"}
                    )
                    continue

                room = mongo_details["rooms"].find_one({"_id": ObjectId(room_id)})
                if not room:
                    await websocket.send_json(
                        {"type": "error", "message": "Room not found"}
                    )
                    continue
                st = room.get("status")
                if st not in (STATUS_CUISINE_VOTING, STATUS_RESTAURANT_VOTING):
                    await websocket.send_json(
                        {"type": "error", "message": "Voting is not active"}
                    )
                    continue
                if username in room.get("voters", []):
                    await websocket.send_json(
                        {"type": "error", "message": "You have already voted"}
                    )
                    continue

                result = mongo_details["rooms"].update_one(
                    {
                        "_id": ObjectId(room_id),
                        "status": st,
                        "options.id": option_key,
                        "voters": {"$ne": username},
                    },
                    {"$inc": {"options.$.votes": 1}, "$push": {"voters": username}},
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
                if updated_room.get("status") == STATUS_CUISINE_VOTING:
                    await maybe_finish_cuisine_voting_early(room_id, updated_room)
                elif updated_room.get("status") == STATUS_RESTAURANT_VOTING:
                    await maybe_finish_restaurant_voting_early(room_id, updated_room)

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
    except Exception:
        logger.exception("Unexpected WS error  room=%s", room_id)
        uname = manager.disconnect(room_id, websocket)
        asyncio.create_task(
            manager.maybe_promote_host_after_disconnect(room_id, uname)
        )
