#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"

if [[ ! -d .venv ]]; then
  python3 -m venv .venv
fi

.venv/bin/pip install --upgrade pip -q
.venv/bin/pip install -r backend/requirements.txt -q

.venv/bin/python -m uvicorn backend.main:app --reload --host 0.0.0.0 --port 8080
