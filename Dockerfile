# syntax=docker/dockerfile:1.7
FROM python:3.11-slim

ENV PIP_NO_CACHE_DIR=1 PIP_DEFAULT_TIMEOUT=120 PYTHONUNBUFFERED=1

# OS deps commonly needed by TTS stacks
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential git ffmpeg libsndfile1 libgl1 ca-certificates \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# (Optional but recommended) Preinstall Torch CPU wheels explicitly
ARG TORCH_VERSION=2.4.1
RUN python -m pip install --upgrade pip setuptools wheel \
 && python -m pip install --index-url https://download.pytorch.org/whl/cpu \
    torch==${TORCH_VERSION} torchaudio

# Install your TTS lib — choose one:
# 1) From PyPI (if published & compatible)
# RUN pip install --no-cache-dir chatterbox-tts==<pin-exact-version>
# 2) From Git (most reliable until PyPI is ready)
# RUN pip install --no-cache-dir git+https://github.com/<org>/<repo>@<tag>#egg=chatterbox-tts

# Copy the rest of your app and install its deps
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
