#!/bin/bash
set -e

# Run the download script with the virtual environment
echo "Checking for model downloads..."
/app/venv/bin/python /app/download.py --output-dir /models

# Build the llama-server command arguments
LLAMA_ARGS=(
    "--host" "0.0.0.0"
    "--port" "${PORT:-8080}"
    "--model" "/models/${API_NAME}/${MODEL_FILE}"
    "--n-gpu-layers" "${GPU_LAYERS:-99}"
    "--ctx-size" "${CTX_SIZE:-16384}"
    "--parallel" "${PARALLEL:-4}"
)

# Add alias if API_NAME is set
if [ -n "$API_NAME" ]; then
    LLAMA_ARGS+=("--alias" "${API_NAME}")
fi

# Add continuous batching if enabled
if [ "$CONT_BATCHING" = "true" ]; then
    LLAMA_ARGS+=("--cont-batching")
fi

# Download chat template if URL is provided
if [ -n "$CHAT_TEMPLATE_URL" ]; then
    echo "Downloading chat template..."
    curl -sSL "$CHAT_TEMPLATE_URL" -o "/models/${API_NAME}/chat_template.jinja"
    LLAMA_ARGS+=("--chat-template-file" "/models/${API_NAME}/chat_template.jinja")
fi

# Add any additional arguments passed to the container
LLAMA_ARGS+=("$@")

# Execute llama-server
echo "Starting llama-server with arguments: ${LLAMA_ARGS[@]}"
exec /app/llama-server "${LLAMA_ARGS[@]}"
