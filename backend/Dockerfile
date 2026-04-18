FROM python:3.12-slim

WORKDIR /app

# Repo runs as `uvicorn backend.main:app` from the project root; imports are
# `backend.*`. Mirror that layout so `backend` is an importable package.
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app

COPY requirements.txt ./backend/
RUN pip install --no-cache-dir -r backend/requirements.txt

COPY . ./backend/

EXPOSE 8080

CMD ["uvicorn", "backend.main:app", "--host", "0.0.0.0", "--port", "8080"]
