# Where Should We Eat?

A real-time app that helps groups decide on a restaurant through live voting. Create a room, add options, vote, and get a winner in under 2 minutes.

## Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend**: FastAPI (Python)
- **Real-time**: WebSockets + polling fallback

## Prerequisites

- Flutter SDK (3.0+)
- Python 3.10+
- pip (or uv)

## Local Setup (without Docker)

### 1. Clone and enter the project

```bash
cd Where-Should-We-Eat
```

### 2. Backend (FastAPI)

From the project root:

```bash
python -m venv .venv
source .venv/bin/activate   # On Windows: .venv\Scripts\activate
pip install -r backend/requirements.txt
uvicorn backend.main:app --reload --host 0.0.0.0 --port 8080
```

Backend runs at: **http://localhost:8080**

- API docs: http://localhost:8080/docs

### 3. Frontend (Flutter)

In a new terminal:

```bash
cd frontend
flutter pub get
flutter run
```

Run on a connected device or simulator (iOS/Android), or use `flutter run -d chrome` for web.

The app expects the API at **http://localhost:8080** by default.

## Project Structure

```
Where-Should-We-Eat/
├── backend/           # FastAPI app
│   ├── main.py
│   ├── store.py
│   ├── services/
│   └── requirements.txt
├── frontend/           # Flutter app
│   ├── lib/
│   │   ├── api_client.dart
│   │   ├── models.dart
│   │   ├── providers/
│   │   ├── screens/
│   │   └── ...
│   └── pubspec.yaml
└── README.md
```

## Docker (3 containers)

**Docker must be running.** If you use [Colima](https://github.com/abiosoft/colima), start it first (`colima start`). If the error mentions `colima/.../docker.sock` and “no such file”, Colima is stopped. With Docker Desktop instead, ensure the app is running and `docker context use default` (or your Desktop context) if you previously switched to Colima.

This repo can run as 3 services:
- `frontend` (Flutter web + Nginx) at [http://localhost:3000](http://localhost:3000)
- `backend` (FastAPI) at [http://localhost:8080](http://localhost:8080)
- `db` (MongoDB) at `localhost:27017`

### 1) Prepare backend env

Create `backend/.env` with the settings your backend expects (`MONGO_DB`, `MONGO_ROOMS_COLLECTION`, API keys, etc.).
`MONGO_URI` is overridden in Docker Compose to point to the Mongo container.

### 2) Build and run

Use whichever Compose command your machine supports:

```bash
docker compose up --build
```

or

```bash
docker-compose up --build
```

### 3) Stop

```bash
docker compose down
```

or

```bash
docker-compose down
```

To also remove the Mongo volume:

```bash
docker compose down -v
```

or

```bash
docker-compose down -v
```

## Notes

- The only project-level README is this root `README.md`.
- `frontend/` and `backend/` do not contain app-level README files.