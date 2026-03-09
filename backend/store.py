"""
Store for rooms and users. Implement with DB or in-memory storage.
"""


def get_room(code: str) -> dict | None:
    """Return room dict for code, or None if not found."""
    return None


def set_room(room: dict) -> None:
    """Persist room (e.g. by code)."""
    pass


def get_user(user_id: str) -> dict | None:
    """Return user dict for id, or None if not found."""
    return None


def set_user(user: dict) -> None:
    """Persist user (e.g. by id)."""
    pass


def generate_room_code(length: int = 6) -> str:
    """Return a unique room code of given length. Implement with storage check."""
    return "ABCD12"
