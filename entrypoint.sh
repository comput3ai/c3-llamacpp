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
    "--batch-size" "${BATCH_SIZE:-2048}"
    "--ubatch-size" "${UBATCH_SIZE:-512}"
)

# Add alias if API_NAME is set
if [ -n "$API_NAME" ]; then
    LLAMA_ARGS+=("--alias" "${API_NAME}")
fi

# Add continuous batching if enabled
if [ "$CONT_BATCHING" = "true" ]; then
    LLAMA_ARGS+=("--cont-batching")
fi

# Add tensor split configuration if specified
if [ -n "$TENSOR_SPLIT" ]; then
    LLAMA_ARGS+=("--tensor-split" "${TENSOR_SPLIT}")
fi

# Add split mode if specified
if [ -n "$SPLIT_MODE" ]; then
    LLAMA_ARGS+=("--split-mode" "${SPLIT_MODE}")
fi

# Add main GPU selection if specified
if [ -n "$MAIN_GPU" ]; then
    LLAMA_ARGS+=("--main-gpu" "${MAIN_GPU}")
fi

# Add NUMA configuration if specified
if [ -n "$NUMA" ]; then
    LLAMA_ARGS+=("--numa" "${NUMA}")
fi

# Add KV cache type for K if specified
if [ -n "$CACHE_TYPE_K" ]; then
    LLAMA_ARGS+=("--cache-type-k" "${CACHE_TYPE_K}")
fi

# Add KV cache type for V if specified
if [ -n "$CACHE_TYPE_V" ]; then
    LLAMA_ARGS+=("--cache-type-v" "${CACHE_TYPE_V}")
fi

# Enable flash attention if specified
if [ "$FLASH_ATTN" = "true" ]; then
    LLAMA_ARGS+=("--flash-attn")
fi

# Enable memory locking if specified
if [ "$MLOCK" = "true" ]; then
    LLAMA_ARGS+=("--mlock")
fi

# Add tensor override for MoE offloading if specified
if [ -n "$OVERRIDE_TENSOR" ]; then
    LLAMA_ARGS+=("--override-tensor" "${OVERRIDE_TENSOR}")
fi

# Download chat template if URL is provided
if [ -n "$CHAT_TEMPLATE_URL" ]; then
    echo "Downloading chat template..."
    curl -sSL "$CHAT_TEMPLATE_URL" -o "/models/${API_NAME}/chat_template.jinja"
    # Enable jinja processing for custom templates
    LLAMA_ARGS+=("--jinja")
    LLAMA_ARGS+=("--chat-template-file" "/models/${API_NAME}/chat_template.jinja")
fi

# Handle API key - unset if empty
if [ -z "${LLAMA_API_KEY:-}" ]; then
    unset LLAMA_API_KEY
else
    LLAMA_ARGS+=("--api-key" "$LLAMA_API_KEY")
fi

# Add any additional arguments passed to the container
LLAMA_ARGS+=("$@")

# Execute llama-server
echo "Starting llama-server with arguments: ${LLAMA_ARGS[@]}"
exec /app/llama-server "${LLAMA_ARGS[@]}"
