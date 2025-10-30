# syntax=docker/dockerfile:1.7
FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DEFAULT_TIMEOUT=120

# --- OS deps commonly required by TTS / audio stacks ---
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    ffmpeg \
    libsndfile1 \
    libgl1 \
    ca-certificates \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Show Python/pip versions in build logs (helps future debugging)
RUN python -V && pip -V

# --- Preinstall Torch CPU wheels explicitly (adjust versions if needed) ---
# If you later run on GPU images, switch the index-url to cu121, etc.
ARG TORCH_VERSION=2.4.1
RUN python -m pip install --upgrade pip setuptools wheel && \
    python -m pip install --index-url https://download.pytorch.org/whl/cpu \
      torch==${TORCH_VERSION} torchaudio==${TORCH_VERSION}

# --- Put only constraint files first (for layer caching) ---
COPY constraints.txt ./constraints.txt

# --- Install Python deps from requirements using constraints ---
COPY requirements.txt ./requirements.txt
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --no-deps -r requirements.txt --constraint constraints.txt || \
    (echo "---- pip failed, showing verbose output ----" && \
     PIP_VERBOSE=1 pip -vvv install -r requirements.txt --constraint constraints.txt)

# --- Now copy the rest of the app ---
COPY . .

# Example entrypoint (adjust to your server)
# CMD ["python", "-m", "server"]
