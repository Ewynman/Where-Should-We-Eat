# Where Should We Eat?

A real-time app that helps groups decide on a restaurant through live voting. Create a room, add options, vote, and get a winner in under 2 minutes.

## Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend**: FastAPI (Python)
- **Real-time**: Socket.IO (WebSockets)

## Prerequisites

- Flutter SDK (3.0+)
- Python 3.10+
- pip (or uv)

## Setup

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

## Development

- Run backend and frontend in separate terminals.
- Backend: `uvicorn backend.main:app --reload --port 8080` (from project root)
- Frontend: `flutter run` (from `frontend/`)

See individual files for TODO items and implementation notes.