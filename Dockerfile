# Use the official llama.cpp CUDA server image as base
FROM ghcr.io/ggml-org/llama.cpp:server-cuda

# Install Python and required system packages
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create models directory
RUN mkdir -p /models

# Set working directory to /app (where llama-server expects to be)
WORKDIR /app

# Create Python virtual environment in /app/venv
RUN python3 -m venv /app/venv

# Copy requirements and install Python packages in venv
COPY requirements.txt /app/
RUN /app/venv/bin/pip install --upgrade pip && \
    /app/venv/bin/pip install --no-cache-dir -r requirements.txt

# Copy our download script and entrypoint
COPY download.py /app/
COPY entrypoint.sh /app/
RUN chmod +x /app/download.py /app/entrypoint.sh

# Set environment variables for HuggingFace cache and Python output
ENV HF_HOME=/models/hf_cache
ENV PYTHONUNBUFFERED=1

# Set the entrypoint to our wrapper script
ENTRYPOINT ["/app/entrypoint.sh"]