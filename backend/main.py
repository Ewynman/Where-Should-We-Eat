"""
Where Should We Eat? - FastAPI Backend
TODO: Add WebSocket routes for real-time room/voting updates
TODO: Add REST endpoints: create room, join room, add options, vote
TODO: Integrate database (PostgreSQL/SQLite) for Room, User, Option models
TODO: Add room code generation (5-6 chars, unique)
TODO: Add vote validation (1 vote per user, duplicate prevention)
TODO: Add timer logic (host starts, countdown, auto-finish)
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="Where Should We Eat?", version="0.1.0")

# TODO: Restrict origins in production
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
def root():
    """Health check / API root."""
    return {"message": "Where Should We Eat? API", "status": "ok"}


@app.get("/health")
def health():
    """Health check endpoint."""
    return {"status": "healthy"}
