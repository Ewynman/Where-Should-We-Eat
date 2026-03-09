import logging
import sys
import uuid
from pathlib import Path

# When run as "uvicorn backend.main:app" from project root, backend dir must be on path
_backend_dir = Path(__file__).resolve().parent
if str(_backend_dir) not in sys.path:
    sys.path.insert(0, str(_backend_dir))

import socketio
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

load_dotenv(_backend_dir / ".env")

app = FastAPI(title="Where Should We Eat?", version="0.1.0")

# Socket.IO for real-time room_update broadcasts (TODO: emit when room state changes)
sio = socketio.AsyncServer(async_mode="asgi", cors_allowed_origins="*")
sio_app = socketio.ASGIApp(sio)
app.mount("/socket.io", sio_app)


@sio.event
async def connect(sid, environ):
    pass


@sio.event
async def disconnect(sid):
    pass


@sio.event
async def join_room(sid, data):
    if isinstance(data, str):
        code = data.strip().upper()
    else:
        code = (data or "").strip().upper()
    if code:
        await sio.enter_room(sid, code)


@sio.event
async def leave_room(sid, data):
    if isinstance(data, str):
        code = data.strip().upper()
    else:
        code = (data or "").strip().upper()
    if code:
        await sio.leave_room(sid, code)


async def broadcast_room_update(room_code: str) -> None:
    """TODO: load room from store and emit room_update to room."""
    pass


app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


logger = logging.getLogger("where-should-we-eat")
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
)

MAX_OPTIONS = 10

# --- Mock data for frontend. Use code ABCD12 to join/get room. ---
MOCK_ROOM_CODE = "ABCD12"
MOCK_HOST_ID = "mock-host-id"
MOCK_ROOM_ID = "mock-room-id"


def _mock_room_response(
    status: str = "waiting",
    options: list[dict] | None = None,
    participants: list[dict] | None = None,
) -> dict:
    if options is None:
        options = []
    if participants is None:
        participants = [
            {"id": MOCK_HOST_ID, "name": "Host", "hasVoted": False},
        ]
    return {
        "id": MOCK_ROOM_ID,
        "code": MOCK_ROOM_CODE,
        "hostId": MOCK_HOST_ID,
        "status": status,
        "endTime": None,
        "options": options,
        "participants": participants,
    }


# --- Pydantic request bodies (API contract) ---


class CreateRoomBody(BaseModel):
    name: str


class JoinRoomBody(BaseModel):
    code: str
    name: str


class AddOptionBody(BaseModel):
    name: str
    userId: str
    cuisineType: str


class VoteBody(BaseModel):
    optionId: str
    userId: str


class RestartBody(BaseModel):
    userId: str


class StartVotingBody(BaseModel):
    userId: str
    durationSeconds: int = 60
    latitude: float
    longitude: float


# --- Route handlers (templates: mock responses only) ---


@app.middleware("http")
async def request_logger(request: Request, call_next):
    logger.info("[REQ] %s %s", request.method, request.url.path)
    response = await call_next(request)
    logger.info("[RES] %s %s -> %s", request.method, request.url.path, response.status_code)
    return response


@app.get("/")
def root():
    return {"message": "Where Should We Eat? API", "status": "ok"}


@app.get("/health")
def health():
    return {"status": "healthy"}


@app.post("/api/rooms", status_code=201)
async def create_room(body: CreateRoomBody):
    # TODO: validate name, generate room + host via store, persist, broadcast.
    room = _mock_room_response()
    user = {"id": MOCK_HOST_ID, "name": (body.name.strip() or "Host")}
    return {"room": room, "user": user}


@app.post("/api/rooms/join")
async def join_room(body: JoinRoomBody):
    # TODO: load room by code from store, validate, add user, persist, broadcast.
    room = _mock_room_response()
    user = {"id": str(uuid.uuid4()), "name": (body.name.strip() or "Guest")}
    return {"room": room, "user": user}


@app.get("/api/rooms/{room_code}")
async def get_room(room_code: str):
    # TODO: load room from store, maybe_finish_room, return room_to_response.
    room = _mock_room_response()
    return room


@app.post("/api/rooms/{room_code}/options", status_code=201)
async def add_option(room_code: str, body: AddOptionBody):
    # TODO: ensure room, ensure user in room, validate status/limits, append option, persist, broadcast.
    option = {
        "id": str(uuid.uuid4()),
        "roomId": MOCK_ROOM_ID,
        "name": (body.name.strip() or "Option"),
        "voteCount": 0,
        "cuisineType": (body.cuisineType.strip() or "cuisine").lower(),
        "source": "cuisine",
    }
    return option


@app.post("/api/rooms/{room_code}/start")
async def start_voting(room_code: str, body: StartVotingBody):
    # TODO: ensure room, ensure host, set status to cuisine_voting, persist, broadcast.
    return {}


@app.post("/api/rooms/{room_code}/vote")
async def vote(room_code: str, body: VoteBody):
    # TODO: ensure room and user, apply vote, maybe_finish_room, persist, broadcast.
    return {}


@app.post("/api/rooms/{room_code}/restart")
async def restart_room(room_code: str, body: RestartBody):
    # TODO: ensure room, ensure host, reset status/options, persist, broadcast.
    room = _mock_room_response(status="waiting", options=[])
    return room
