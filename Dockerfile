# syntax=docker/dockerfile:1.7
FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DEFAULT_TIMEOUT=120

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential git ffmpeg libsndfile1 libgl1 ca-certificates \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN python -V && pip -V

# Cleanest approach: DO NOT preinstall torch here.
# Let pip resolve it once, constrained by your pin file.

COPY constraints.txt ./constraints.txt
COPY requirements.txt ./requirements.txt

RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --upgrade pip setuptools wheel && \
    pip install -r requirements.txt --constraint constraints.txt || \
    (echo "---- pip failed, retrying with verbose ----" && \
     PIP_VERBOSE=1 pip -vvv install -r requirements.txt --constraint constraints.txt)

COPY . .
