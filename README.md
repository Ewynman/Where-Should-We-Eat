# Where Should We Eat?

A real-time web app that helps groups decide on a restaurant through live voting. Create a room, add options, vote, and get a winner in under 2 minutes.

## Tech Stack

- **Frontend**: Next.js, React, TailwindCSS
- **Backend**: FastAPI (Python)
- **Real-time**: WebSockets (to be implemented)

## Prerequisites

- Node.js 18+
- Python 3.10+
- npm (or pnpm/yarn)

## Setup

### 1. Clone and enter the project

```bash
cd Where-Should-We-Eat
```

### 2. Backend (FastAPI)

```bash
cd backend
python -m venv venv
source venv/bin/activate   # On Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Backend runs at: **http://localhost:8000**

- API docs: http://localhost:8000/docs

### 3. Frontend (Next.js)

In a new terminal:

```bash
cd frontend
npm install
npm run dev
```

Frontend runs at: **http://localhost:3000**

## Project Structure

```
Where-Should-We-Eat/
├── backend/           # FastAPI app
│   ├── main.py
│   └── requirements.txt
├── frontend/          # Next.js app
│   ├── src/
│   │   ├── app/
│   │   └── lib/
│   └── package.json
└── README.md
```

## Development

- Run backend and frontend in separate terminals.
- Backend: `uvicorn main:app --reload --port 8000`
- Frontend: `npm run dev`

See individual files for TODO items and implementation notes.
