# Use latest RunPod base with CUDA 12.2 and Python 3.11
FROM runpod/base:0.6.2-cuda12.2.0

ARG BUILD_REV="stamp-root-2025-10-29-c"
RUN echo ">>> BUILD STAMP: ${BUILD_REV}"

# System packages needed for audio I/O and HTTPS
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ffmpeg \
    libsndfile1 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Env for predictable installs and Torch archs
ENV TORCH_CUDA_ARCH_LIST="8.0;8.6;8.9;9.0+PTX" \
    HF_HOME=/root/.cache/huggingface \
    TORCH_HOME=/root/.cache/torch \
    UV_SYSTEM_PYTHON=1

# Copy requirements first for better caching
COPY requirements.txt /app/requirements.txt

# Install Python deps with uv (pre-installed in runpod/base)
# Point to cu121 wheels for PyTorch compatibility
RUN uv pip install --system \
    --extra-index-url https://download.pytorch.org/whl/cu121 \
    -r /app/requirements.txt

# Copy app code
COPY handler.py /app/handler.py

# Optional: Pre-download model at build time for faster cold starts
# RUN python -c "from chatterbox.tts import ChatterboxTTS; ChatterboxTTS.from_pretrained(device='cpu')" || true

# Default command (RunPod overrides entrypoint when invoking the handler)
CMD ["python", "-u", "handler.py"]
