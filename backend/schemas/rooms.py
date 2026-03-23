from pydantic import BaseModel


class CreateRoomBody(BaseModel):
    host_name: str
    latitude: float
    longitude: float


class JoinRoomBody(BaseModel):
    """Join by room `code` (what users type). `room_id` is optional for deep links."""
    username: str
    code: str
    room_id: str = ""


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
