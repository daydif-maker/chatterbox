# syntax=docker/dockerfile:1.7
FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DEFAULT_TIMEOUT=120

# System deps commonly required by TTS/audio stacks
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    ffmpeg \
    libsndfile1 \
    libgl1 \
    ca-certificates \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# See versions in logs for future debugging
RUN python -V && pip -V

# Preinstall Torch CPU wheels (prevents most pip failures)
# If you later need CUDA on a GPU image, swap the index-url to cu121.
ARG TORCH_VERSION=2.4.1
RUN python -m pip install --upgrade pip setuptools wheel && \
    python -m pip install --index-url https://download.pytorch.org/whl/cpu \
      torch==${TORCH_VERSION} torchaudio==${TORCH_VERSION}

# Put constraint file first to maximize layer caching
COPY constraints.txt ./constraints.txt

# Install Python deps with constraints; show verbose logs if it fails
COPY requirements.txt ./requirements.txt
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --no-deps -r requirements.txt --constraint constraints.txt || \
    (echo "---- pip failed, retrying with verbose output ----" && \
     PIP_VERBOSE=1 pip -vvv install -r requirements.txt --constraint constraints.txt)

# Copy the rest of your app
COPY . .

# Example: adjust to your server entrypoint
# CMD ["python", "-m", "server"]
