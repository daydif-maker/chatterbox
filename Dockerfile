# CUDA 12.1 + Python 3.11 base (matches cu121 wheels below)
FROM runpod/base:0.6.1-cuda12.1.1-py311

# System packages needed for audio I/O and HTTPS
RUN apt-get update && \
    apt-get install -y --no-install-recommends ffmpeg libsndfile1 ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Env for predictable pip installs and Torch archs
ENV PIP_NO_CACHE_DIR=1 \
    TORCH_CUDA_ARCH_LIST="8.0;8.6;8.9;9.0+PTX" \
    HF_HOME=/root/.cache/huggingface \
    TORCH_HOME=/root/.cache/torch

# Install Python deps with pip (no uv). Point to cu121 wheels for Torch.
COPY requirements.txt /app/requirements.txt
RUN python -m pip install --upgrade pip && \
    python -m pip install --extra-index-url https://download.pytorch.org/whl/cu121 -r /app/requirements.txt

# App code
# (If you have a package/module, you can copy the whole repo instead.)
COPY handler.py /app/handler.py

# Default command (RunPod overrides entrypoint when invoking the handler)
CMD ["python", "-u", "handler.py"]
