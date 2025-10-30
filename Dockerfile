# Use RunPod base with CUDA 12.2 and Python 3.11
FROM runpod/base:0.6.2-cuda12.2.0

ARG BUILD_REV="stamp-root-2025-10-29-g"
RUN echo ">>> BUILD STAMP: ${BUILD_REV}"

# System packages needed for audio I/O and HTTPS
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ffmpeg \
    libsndfile1 \
    ca-certificates \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Env for predictable installs and Torch archs
ENV TORCH_CUDA_ARCH_LIST="8.0;8.6;8.9;9.0+PTX" \
    HF_HOME=/root/.cache/huggingface \
    TORCH_HOME=/root/.cache/torch

# Upgrade pip first
RUN pip install --no-cache-dir --upgrade pip

# Install PyTorch with CUDA 12.1 support FIRST (avoid conflicts)
RUN pip install --no-cache-dir \
    --extra-index-url https://download.pytorch.org/whl/cu121 \
    torch==2.4.1 \
    torchaudio==2.4.1

# Install basic dependencies
RUN pip install --no-cache-dir \
    runpod==1.6.0 \
    ffmpeg-python==0.2.0 \
    "numpy>=1.26,<2.0" \
    "soundfile>=0.12"

# Install chatterbox-tts from GitHub (0.1.0 doesn't exist on PyPI)
RUN pip install --no-cache-dir git+https://github.com/resemble-ai/chatterbox.git

# Copy app code
COPY handler.py /app/handler.py

# Optional: Pre-download model at build time for faster cold starts
# RUN python -c "from chatterbox.tts import ChatterboxTTS; ChatterboxTTS.from_pretrained(device='cpu')" || true

# Default command
CMD ["python", "-u", "handler.py"]
