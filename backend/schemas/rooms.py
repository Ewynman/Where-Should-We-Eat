from pydantic import BaseModel, Field


class CreateRoomBody(BaseModel):
    host_name: str
    latitude: float
    longitude: float
    max_capacity: int = Field(default=10, ge=2, le=20)


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


class KickBody(BaseModel):
    userId: str
    targetUsername: str


class TransferHostBody(BaseModel):
    userId: str
    newHostUsername: str
