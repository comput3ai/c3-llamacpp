# 🚀 c3-llamacpp

A Docker container that seamlessly combines [llama.cpp](https://github.com/ggml-org/llama.cpp) with automatic HuggingFace model downloads. Run any GGUF model with a single command!

## 🌟 Features

- **Automatic Model Downloads**: Downloads GGUF models from HuggingFace at runtime
- **GPU Acceleration**: Built on llama.cpp's official CUDA image for optimal performance
- **OpenAI Compatible API**: Drop-in replacement for OpenAI API endpoints
- **Flexible Configuration**: Environment variables for easy customization
- **Smart Caching**: Models are downloaded once and reused across restarts

## 🙏 Credits

This project builds upon the excellent work of:
- [llama.cpp](https://github.com/ggml-org/llama.cpp) - High-performance C++ inference engine
- [Unsloth](https://github.com/unslothai/unsloth) - Providing optimized GGUF quantizations
- The HuggingFace community for hosting and sharing models

## 📦 Quick Start

### Pull the image

```bash
docker pull ghcr.io/comput3ai/c3-llamacpp:latest
```

### Run with your model

```bash
docker run --gpus all \
  -e API_NAME=deepseek-r1 \
  -e MODEL_REPO=unsloth/DeepSeek-R1-0528-Qwen3-8B-GGUF \
  -e MODEL_PATTERN="*Q4_0.gguf" \
  -e MODEL_FILE=DeepSeek-R1-0528-Qwen3-8B-Q4_0.gguf \
  -p 8080:8080 \
  ghcr.io/comput3ai/c3-llamacpp:latest
```

## 🔧 Configuration

### Required Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `API_NAME` | Model alias for the API | `deepseek-r1` |
| `MODEL_REPO` | HuggingFace repository | `unsloth/DeepSeek-R1-0528-Qwen3-8B-GGUF` |
| `MODEL_PATTERN` | File pattern to download | `*Q4_0.gguf` |
| `MODEL_FILE` | Main model file | `DeepSeek-R1-0528-Qwen3-8B-Q4_0.gguf` |

### Optional Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | Server port | `8080` |
| `GPU_LAYERS` | Number of layers to offload to GPU | `99` |
| `CTX_SIZE` | Context window size | `16384` |
| `PARALLEL` | Max parallel requests | `4` |
| `CONT_BATCHING` | Enable continuous batching | `false` |
| `HF_TOKEN` | HuggingFace token for private repos | - |
| `CHAT_TEMPLATE_URL` | URL to download chat template | - |

### Performance Optimization Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `BATCH_SIZE` | Logical maximum batch size | `2048` |
| `UBATCH_SIZE` | Physical maximum batch size | `512` |
| `CACHE_TYPE_K` | KV cache data type for K (f16, q4_0, etc.) | - |
| `CACHE_TYPE_V` | KV cache data type for V (f16, q4_0, etc.) | - |
| `FLASH_ATTN` | Enable Flash Attention | - |
| `MLOCK` | Lock model in RAM | - |
| `OVERRIDE_TENSOR` | Override tensor buffer types | - |
| `WEBUI` | Enable the web interface | `false` |
| `LLAMA_API_KEY` | API key for authentication | - |

#### Optimization Tips

For **Kimi K2** and other large MoE models:
- Set `CACHE_TYPE_K=q4_0` to compress KV cache (recommended by Unsloth)
- Set `OVERRIDE_TENSOR=.ffn_.*_exps.=CPU` to offload MoE layers to CPU
- This allows fitting larger models with limited VRAM

## 📚 Examples

### Running Kimi K2

#### On Datacenter GPUs (H200, H100, A100 80GB)

```bash
docker run --gpus all \
  -e API_NAME=kimi-k2 \
  -e MODEL_REPO=unsloth/Kimi-K2-Instruct-GGUF \
  -e MODEL_PATTERN="Q8_0/*" \
  -e MODEL_FILE=Q8_0/Kimi-K2-Instruct-Q8_0-00001-of-00023.gguf \
  -e CTX_SIZE=32768 \
  -e CHAT_TEMPLATE_URL=https://huggingface.co/unsloth/Kimi-K2-Instruct/raw/main/chat_template.jinja \
  -e FLASH_ATTN=true \
  -e MLOCK=true \
  -e PARALLEL=8 \
  -e BATCH_SIZE=4096 \
  -p 8080:8080 \
  ghcr.io/comput3ai/c3-llamacpp:latest
```

#### On Consumer GPUs (RTX 3090/4090 24GB)

```bash
docker run --gpus all \
  -e API_NAME=kimi-k2 \
  -e MODEL_REPO=unsloth/Kimi-K2-Instruct-GGUF \
  -e MODEL_PATTERN="UD-TQ1_0/*" \
  -e MODEL_FILE=UD-TQ1_0/Kimi-K2-Instruct-UD-TQ1_0-00001-of-00005.gguf \
  -e CTX_SIZE=16384 \
  -e CHAT_TEMPLATE_URL=https://huggingface.co/unsloth/Kimi-K2-Instruct/raw/main/chat_template.jinja \
  -e CACHE_TYPE_K=q4_0 \
  -e OVERRIDE_TENSOR=".ffn_.*_exps.=CPU" \
  -e FLASH_ATTN=true \
  -p 8080:8080 \
  ghcr.io/comput3ai/c3-llamacpp:latest
```

Note: The consumer GPU example uses the 1.8-bit quantized version (245GB) instead of Q8_0 (1TB+) and offloads MoE layers to CPU.

### Using the API

#### With curl

```bash
# Chat completion
curl -X POST http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "deepseek-r1",
    "messages": [
      {"role": "user", "content": "Hello! How are you?"}
    ],
    "temperature": 0.7
  }'

# With API key authentication
curl -X POST http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-api-key" \
  -d '{
    "model": "deepseek-r1",
    "messages": [
      {"role": "user", "content": "Hello! How are you?"}
    ],
    "temperature": 0.7
  }'

# Streaming response
curl -X POST http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "deepseek-r1",
    "messages": [
      {"role": "user", "content": "Write a haiku about coding"}
    ],
    "stream": true
  }'

# Check model info
curl http://localhost:8080/v1/models

# Health check
curl http://localhost:8080/health
```

#### With Python

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:8080/v1",
    api_key="not-needed"  # Use actual key if LLAMA_API_KEY is set
)

response = client.chat.completions.create(
    model="deepseek-r1",  # Uses the API_NAME
    messages=[
        {"role": "user", "content": "Hello!"}
    ]
)
print(response.choices[0].message.content)
```

## 🐳 Deployment Options

### Option 1: Docker Run (Simple)

```bash
docker run -t --gpus all \
  -e API_NAME=deepseek-r1 \
  -e MODEL_REPO=unsloth/DeepSeek-R1-0528-Qwen3-8B-GGUF \
  -e MODEL_PATTERN="*Q4_0.gguf" \
  -e MODEL_FILE=DeepSeek-R1-0528-Qwen3-8B-Q4_0.gguf \
  -p 8080:8080 \
  ghcr.io/comput3ai/c3-llamacpp:latest
```

### Option 2: Docker Compose (Recommended)

1. Copy the environment template:
```bash
cp env.sample .env
```

2. Edit `.env` with your model configuration:
```env
API_NAME=deepseek-r1
MODEL_REPO=unsloth/DeepSeek-R1-0528-Qwen3-8B-GGUF
MODEL_PATTERN=*Q4_0.gguf
MODEL_FILE=DeepSeek-R1-0528-Qwen3-8B-Q4_0.gguf

# Optional: Enable API authentication
# LLAMA_API_KEY=your-secret-api-key

# Optional: Enable Web UI
# WEBUI=true
```

3. Start the service:
```bash
docker-compose up -d
```

### Option 3: Docker Compose with Traefik (Production)

For HTTPS support with automatic SSL certificates:

1. Copy and edit the environment file:
```bash
cp env.sample .env
```

2. Add Traefik configuration to `.env`:
```env
# Model configuration
API_NAME=deepseek-r1
MODEL_REPO=unsloth/DeepSeek-R1-0528-Qwen3-8B-GGUF
MODEL_PATTERN=*Q4_0.gguf
MODEL_FILE=DeepSeek-R1-0528-Qwen3-8B-Q4_0.gguf

# Traefik configuration
TRAEFIK_HOSTNAME=llama.example.com
TRAEFIK_EMAIL=admin@example.com
```

3. Start with Traefik:
```bash
docker-compose -f docker-compose.traefik.yaml up -d
```

Your service will be available at `https://llama.example.com` with automatic SSL certificates from Let's Encrypt.

## 🔨 Building Locally

```bash
git clone https://github.com/yourusername/c3-llamacpp
cd c3-llamacpp
docker build -t c3-llamacpp .
```

## 🛠️ How It Works

1. The container starts and runs `download.py` to check if the model exists
2. If not present, it downloads the model from HuggingFace
3. Optional chat template is downloaded if `CHAT_TEMPLATE_URL` is provided
4. llama.cpp server starts with the downloaded model

## 📄 License

BSD 3-Clause License

Copyright (c) 2025, Comput3.ai

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.