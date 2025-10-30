# syntax=docker/dockerfile:1.7
FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DEFAULT_TIMEOUT=120

# --- OS deps commonly required by TTS stacks ---
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    ffmpeg \
    libsndfile1 \
    libgl1 \
    ca-certificates \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# --- Make the pip step noisy so we can see real errors if anything fails ---
RUN python -V && pip -V

# --- (Optional but recommended) Preinstall Torch CPU wheels explicitly ---
# If you need CUDA on a GPU pod, change the index-url to cu121 wheels instead.
ARG TORCH_VERSION=2.4.1
RUN python -m pip install --upgrade pip setuptools wheel && \
    python -m pip install --index-url https://download.pytorch.org/whl/cpu \
      torch==${TORCH_VERSION} torchaudio

# --- Install chatterbox-tts ---
# If the package is NOT on PyPI, install from Git (most reliable):
# NOTE: replace <org>/<repo>@<tag-or-commit> with the actual repo/tag.
RUN pip install --no-cache-dir \
  "git+https://github.com/<org>/<repo>@<tag-or-commit>#egg=chatterbox-tts"

# If it IS on PyPI and supports py3.11, comment the Git line above and uncomment this:
# RUN pip install --no-cache-dir chatterbox-tts==<pin-exact-version>

# --- App deps & code (adjust paths if you use a monorepo) ---
COPY requirements.txt .  # keep this if you have one
RUN if [ -f requirements.txt ]; then pip install --no-cache-dir -r requirements.txt; fi

COPY . .

# --- Default command (adjust to your server) ---
# CMD ["python", "-m", "your_entrypoint"]
