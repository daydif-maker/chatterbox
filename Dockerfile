# Start from a RunPod base image that includes CUDA + Python 3.11
FROM runpod/base:0.6.1-cuda12.1.1-py311

# System deps for audio I/O
RUN apt-get update && \
    apt-get install -y --no-install-recommends ffmpeg libsndfile1 && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Use uv (present in runpod/base) to install faster and reproducibly
COPY requirements.txt /app/requirements.txt
RUN uv pip install --system -r /app/requirements.txt

# Copy your handler + any needed code
COPY handler.py /app/handler.py

# (Optional) cache directory for models
ENV HF_HOME=/root/.cache/huggingface
ENV TORCH_HOME=/root/.cache/torch

# Default command: run the handler file locally (RunPod overrides entrypoint)
CMD ["python", "-u", "handler.py"]
