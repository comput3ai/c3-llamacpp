# 🚀 C3 LlamaCPP ASG - Production LLM Inference Infrastructure

A complete infrastructure solution for deploying [llama.cpp](https://github.com/ggml-org/llama.cpp) inference servers at scale on AWS using Pulumi IaC, Auto Scaling Groups, and automatic model management.

## 📋 Table of Contents

- [Overview](#-overview)
- [Architecture](#-architecture)
- [Features](#-features)
- [Prerequisites](#-prerequisites)
- [Quick Start](#-quick-start)
- [Configuration Guide](#-configuration-guide)
- [Deployment](#-deployment)
- [How It Works](#-how-it-works)
- [API Usage](#-api-usage)
- [Monitoring & Operations](#-monitoring--operations)
- [Troubleshooting](#-troubleshooting)
- [Security](#-security)
- [Examples](#-examples)

## 🌟 Overview

This project provides a production-ready infrastructure for deploying LLM inference servers using llama.cpp. It combines:

- **🐳 Docker Container**: Automatic model downloading and llama.cpp server management
- **☁️ AWS Infrastructure**: Auto Scaling Groups with mixed spot/on-demand instances
- **🔧 Infrastructure as Code**: Pulumi-based deployment for repeatability
- **🔒 Security**: API key authentication, SSL/TLS termination with Traefik
- **📊 Monitoring**: Health checks and metrics endpoints
- **🌍 Multi-Region**: Deploy across multiple AWS regions
- **💰 Cost Optimization**: Spot instance support with graceful shutdown

## 🏗️ Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────┐
│                   Pulumi Stack                  │
├─────────────────────────────────────────────────┤
│ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ │
│ │   Region 1  │ │   Region 2  │ │   Region N  │ │
│ │             │ │             │ │             │ │
│ │ ┌─────────┐ │ │ ┌─────────┐ │ │ ┌─────────┐ │ │
│ │ │   ASG   │ │ │ │   ASG   │ │ │ │   ASG   │ │ │
│ │ │ GPU EC2 │ │ │ │ GPU EC2 │ │ │ │ GPU EC2 │ │ │
│ │ └─────────┘ │ │ └─────────┘ │ │ └─────────┘ │ │
│ │             │ │             │ │             │ │
│ │ ┌─────────┐ │ │ ┌─────────┐ │ │ ┌─────────┐ │ │
│ │ │  EIPs   │ │ │ │  EIPs   │ │ │ │  EIPs   │ │ │
│ │ └─────────┘ │ │ └─────────┘ │ │ └─────────┘ │ │
│ └─────────────┘ └─────────────┘ └─────────────┘ │
│                                                 │
│ ┌─────────────────────────────────────────────┐ │
│ │              Cloudflare DNS                 │ │
│ │         (hostname.domain.com → EIP)         │ │
│ └─────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘
```

### Instance Architecture

```
┌─────────────────────────────────────────────────┐
│                 EC2 Instance                    │
├─────────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────────┐ │
│ │              Traefik                        │ │
│ │    (Reverse Proxy + SSL + Auth)             │ │
│ │            Port 443 (HTTPS)                 │ │
│ └──────────────────┬──────────────────────────┘ │
│                    │                            │
│ ┌──────────────────▼──────────────────────────┐ │
│ │           C3 LlamaCPP Container             │ │
│ │                                             │ │
│ │  ┌────────────┐       ┌──────────────────┐  │ │
│ │  │ Model      │       │ llama.cpp Server │  │ │
│ │  │ Downloader │──────▶│  (OpenAI API)    │  │ │
│ │  └────────────┘       └──────────────────┘  │ │
│ │                                             │ │
│ │              Port 8080 (Internal)           │ │
│ └─────────────────────────────────────────────┘ │
│                                                 │
│ ┌─────────────────────────────────────────────┐ │
│ │         NVIDIA GPU + CUDA Drivers           │ │
│ └─────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘
```

## ✨ Features

### Container Features

- **🤖 Automatic Model Management**: Downloads GGUF models from HuggingFace on first run
- **⚡ GPU Acceleration**: Built on llama.cpp's official CUDA image
- **🔌 OpenAI Compatible API**: Drop-in replacement for OpenAI endpoints
- **📦 Smart Caching**: Models downloaded once and persisted across restarts
- **🎯 Flexible Configuration**: Extensive environment variables for tuning
- **🔧 Performance Optimization**: Support for Flash Attention, KV cache compression, MoE offloading

### Infrastructure Features

- **📈 Auto Scaling**: Mixed spot/on-demand instances with configurable ratios
- **🌐 Multi-Region**: Deploy across any AWS regions
- **🔄 Self-Healing**: Automatic instance replacement on failure
- **🔒 Secure by Default**: API key authentication, SSL/TLS termination
- **🏷️ Elastic IPs**: Stable endpoints with automatic association
- **📊 Monitoring**: Health checks and metrics endpoints
- **🎛️ IaC**: Full Pulumi automation for repeatability

## 📋 Prerequisites

### Required Tools

- **AWS CLI** configured with appropriate credentials
- **Pulumi CLI** (latest version)
- **Python 3.8+** with pip
- **Docker** (for local testing)
- **NVIDIA GPU** (for local testing with GPU)

### AWS Requirements

- AWS account with permissions for:
  - EC2 (instances, security groups, key pairs)
  - IAM (roles, policies, instance profiles)
  - Auto Scaling Groups
  - Elastic IPs
  - Secrets Manager
  - Cloudflare API token (for DNS management)

### GPU Instance Availability

Ensure your AWS account has access to GPU instances in your target regions:
- `p5.48xlarge` - 8x H100 GPUs (640GB VRAM)
- `p5e.48xlarge` - 8x H200 GPUs (1280GB VRAM)
- `g5.xlarge` - 1x A10G GPU (24GB VRAM)
- etc.

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/comput3ai/c3-llamacpp-asg
cd c3-llamacpp-asg
```

### 2. Install Dependencies

```bash
pip install -r requirements.txt
```

### 3. Configure Pulumi

```bash
# Initialize a new stack
pulumi stack init dev

# Set AWS credentials
pulumi config set aws:accessKey YOUR_ACCESS_KEY
pulumi config set aws:secretKey YOUR_SECRET_KEY --secret

# Set Cloudflare configuration
pulumi config set cloudflare-zone-id YOUR_ZONE_ID
pulumi config set domain-name your-domain.com
pulumi config set cloudflare-api-token YOUR_API_TOKEN --secret

# Set API key for authentication
pulumi config set api-key $(openssl rand -hex 32) --secret
```

### 4. Create ASG Configuration

Create `dev.asg.yaml`:

```yaml
deepseek-r1-demo:
  region: us-east-1
  type: g5.xlarge
  on-demand: 0
  hosts:
    - deepseek-demo.your-domain.com
  model_config:
    api_name: deepseek-r1
    model_repo: unsloth/DeepSeek-R1-0528-Qwen3-8B-GGUF
    model_pattern: "*Q4_0.gguf"
    model_file: DeepSeek-R1-0528-Qwen3-8B-Q4_0.gguf
    chat_template_url: https://huggingface.co/unsloth/DeepSeek-R1/raw/main/chat_template.jinja
```

### 5. Deploy

```bash
pulumi up
```

## 🔧 Configuration Guide

### Pulumi Configuration

| Config Key | Description | Required |
|------------|-------------|----------|
| `aws:accessKey` | AWS access key | ✅ |
| `aws:secretKey` | AWS secret key | ✅ |
| `cloudflare-zone-id` | Cloudflare zone ID | ✅ |
| `domain-name` | Base domain for hostnames | ✅ |
| `cloudflare-api-token` | Cloudflare API token | ✅ |
| `api-key` | API key for authentication | ✅ |
| `slug` | Project identifier | ❌ (default: c3-llamacpp) |
| `ssh_keys` | Additional SSH keys | ❌ |

### ASG Configuration (YAML)

The ASG configuration file (`{stack}.asg.yaml`) defines your inference clusters:

```yaml
asg-name:
  # Required fields
  region: us-east-1              # AWS region
  type: p5.48xlarge              # Instance type
  hosts:                         # List of hostnames (determines capacity)
    - host1.domain.com
    - host2.domain.com
  
  # Optional fields
  on-demand: 1                   # Number of on-demand instances (default: 0)
  azs:                          # Specific availability zones
    - us-east-1a
    - us-east-1b
  
  # Model configuration (required)
  model_config:
    api_name: model-name         # API model identifier
    model_repo: org/repo         # HuggingFace repository
    model_pattern: "*.gguf"      # File pattern to download
    model_file: model.gguf       # Main model file
    chat_template_url: https://... # Chat template URL
    
    # Optional performance settings
    ctx_size: 16384              # Context window size
    gpu_layers: 99               # GPU layer offloading
    parallel: 4                  # Max parallel requests
    cont_batching: true          # Continuous batching
    batch_size: 2048             # Logical batch size
    ubatch_size: 512             # Physical batch size
    cache_type_k: q4_0           # KV cache compression
    flash_attn: true             # Flash Attention
    mlock: true                  # Memory locking
    override_tensor: ".ffn_.*_exps.=CPU"  # Tensor placement
```

### Model Configuration Parameters

#### Required Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `api_name` | Model identifier for API calls | `deepseek-r1` |
| `model_repo` | HuggingFace repository | `unsloth/DeepSeek-R1-GGUF` |
| `model_pattern` | File pattern to download | `*Q4_0.gguf` |
| `model_file` | Main model file | `model-Q4_0.gguf` |
| `chat_template_url` | Chat template for formatting | `https://...` |

#### Performance Parameters

| Parameter | Description | Default | Recommended |
|-----------|-------------|---------|-------------|
| `ctx_size` | Context window size | 16384 | 8192-32768 |
| `gpu_layers` | Layers to offload to GPU | 99 | 99 (all) |
| `parallel` | Max parallel requests | 4 | 2-8 |
| `cont_batching` | Enable continuous batching | false | true |
| `batch_size` | Logical batch size | 2048 | 2048-4096 |
| `ubatch_size` | Physical batch size | 512 | 512-1024 |
| `cache_type_k` | KV cache K compression | f16 | q4_0 for large models |
| `cache_type_v` | KV cache V compression | f16 | f16 |
| `flash_attn` | Enable Flash Attention | false | true for H100/H200 |
| `mlock` | Lock model in RAM | false | true with 256GB+ RAM |

## 🚀 Deployment

### Option 1: Standalone Container (Local Testing)

```bash
docker run --gpus all \
  -e API_NAME=deepseek-r1 \
  -e MODEL_REPO=unsloth/DeepSeek-R1-0528-Qwen3-8B-GGUF \
  -e MODEL_PATTERN="*Q4_0.gguf" \
  -e MODEL_FILE=DeepSeek-R1-0528-Qwen3-8B-Q4_0.gguf \
  -p 8080:8080 \
  ghcr.io/comput3ai/c3-llamacpp
```

### Option 2: Full Infrastructure Deployment

1. **Configure ASGs** in `{stack}.asg.yaml`
2. **Deploy infrastructure**:
   ```bash
   pulumi up
   ```
3. **Monitor deployment**:
   ```bash
   pulumi logs -f
   ```
4. **Access endpoints**:
   ```bash
   # Get API key (if configured)
   LLAMA_API_KEY=$(pulumi stack output api-key --show-secrets)
   
   # Test endpoint
   curl -H "Authorization: Bearer $LLAMA_API_KEY" \
        https://host1.domain.com/health -k
   ```

### Option 3: Multi-Stack Deployment

For production environments with separate dev/staging/prod:

```bash
# Development
pulumi stack init dev
pulumi config set ... # Configure
pulumi up

# Production
pulumi stack init prod
pulumi config set ... # Configure with prod values
pulumi up
```

## ⚙️ How It Works

### 1. Infrastructure Provisioning

1. **Pulumi** reads ASG configuration from YAML
2. **Regional resources** are created (VPC, subnets, security groups)
3. **Elastic IPs** are allocated based on capacity
4. **Auto Scaling Groups** are created with launch templates
5. **Cloudflare DNS** records are created for each hostname

### 2. Instance Initialization

When an instance launches:

1. **Cloud-init** runs initialization scripts
2. **EIP association** assigns a stable IP address
3. **Docker** starts with GPU support
4. **Traefik** starts for SSL termination (if using traefik compose)
5. **Model download** begins if not cached
6. **LlamaCPP server** starts when model is ready

### 3. Model Management

The container handles model lifecycle:

1. **Check cache** in `/models/{api_name}/`
2. **Download from HuggingFace** if missing
3. **Download chat template** if specified
4. **Start llama.cpp server** with configuration

### 4. Request Flow

```
Client → HTTPS → Traefik (SSL + Auth) → LlamaCPP (8080) → GPU Processing
```

## 📡 API Usage

### Authentication

If LLAMA_API_KEY is set, all API requests require authentication using the standard OpenAI format:

```bash
curl -H "Authorization: Bearer $LLAMA_API_KEY" https://hostname/endpoint
```

If no LLAMA_API_KEY is configured, the API is open without authentication.

### Endpoints

#### Health Check

```bash
# With authentication
curl -H "Authorization: Bearer $LLAMA_API_KEY" https://hostname/health

# Without authentication (if LLAMA_API_KEY not set)
curl https://hostname/health
```

#### Chat Completions

```bash
curl -X POST https://hostname/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $LLAMA_API_KEY" \
  -d '{
    "model": "deepseek-r1",
    "messages": [
      {"role": "user", "content": "Hello!"}
    ]
  }'
```

#### Streaming

```bash
curl -X POST https://hostname/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $LLAMA_API_KEY" \
  -d '{
    "model": "deepseek-r1",
    "messages": [
      {"role": "user", "content": "Tell me a story"}
    ],
    "stream": true
  }'
```

### Python SDK Usage

```python
from openai import OpenAI

# With authentication
client = OpenAI(
    base_url="https://hostname/v1",
    api_key="your-llama-api-key"  # SDK automatically adds "Bearer" prefix
)

# Without authentication (if LLAMA_API_KEY not set)
client = OpenAI(
    base_url="https://hostname/v1",
    api_key="dummy"  # OpenAI SDK requires a value, but it won't be checked
)

response = client.chat.completions.create(
    model="deepseek-r1",
    messages=[
        {"role": "user", "content": "Hello!"}
    ]
)
print(response.choices[0].message.content)
```

## 📊 Monitoring & Operations

### View Deployment Status

```bash
# List all resources
pulumi stack

# View specific outputs
pulumi stack output

# Get instance IPs
pulumi stack output deepseek-r1-demo-ips
```

### SSH Access

```bash
# Save SSH key
pulumi stack output ssh_private_key --show-secrets > key.pem
chmod 600 key.pem

# Connect to instance
ssh -i key.pem ubuntu@hostname
```

### Container Logs

```bash
# On the instance
docker logs llamacpp -f
docker logs traefik -f
```

### Scaling Operations

```bash
# Edit ASG configuration
vim dev.asg.yaml

# Add more hosts or change instance types
# Then apply changes
pulumi up
```

## 🔧 Troubleshooting

### Common Issues

#### Model Download Failures

```bash
# Check logs
docker logs llamacpp

# Verify HuggingFace token (for private models)
echo $HF_TOKEN

# Check disk space
df -h /models
```

#### GPU Not Detected

```bash
# Verify NVIDIA drivers
nvidia-smi

# Check Docker GPU support
docker run --rm --gpus all nvidia/cuda:12.0-base nvidia-smi
```

#### Authentication Issues

```bash
# Verify API key in llamacpp container
docker exec llamacpp env | grep LLAMA_API_KEY

# Test without auth (health endpoint)
curl https://hostname/health -k
```

#### Instance Not Starting

```bash
# Check cloud-init logs
sudo cat /var/log/cloud-init-output.log

# Verify user data execution
ls -la /home/ubuntu/
```

### Performance Tuning

#### For Large Models (70B+)

```yaml
model_config:
  cache_type_k: q4_0      # Compress KV cache
  ctx_size: 8192          # Reduce context size
  gpu_layers: 80          # Partial GPU offloading
```

#### For High Throughput

```yaml
model_config:
  cont_batching: true
  parallel: 8
  batch_size: 4096
  flash_attn: true
```

#### For Limited VRAM

```yaml
model_config:
  override_tensor: ".ffn_.*_exps.=CPU"  # Offload MoE layers
  cache_type_k: q4_0                     # Compress cache
  ctx_size: 4096                         # Small context
```

## 🔒 Security

### Network Security

- **Security Groups**: Restrictive inbound rules (HTTPS only)
- **SSL/TLS**: Automatic certificate generation via Traefik
- **API Authentication**: Optional API key via LLAMA_API_KEY

### IAM Permissions

Instances have minimal required permissions:
- EC2: Describe tags, associate EIPs
- Secrets Manager: Read API key secret
- No S3 or other service access

### Best Practices

1. **Rotate API keys** regularly
2. **Use private subnets** for instances
3. **Enable VPC Flow Logs** for audit
4. **Restrict security group** sources
5. **Use Systems Manager** for access instead of SSH

## 📚 Examples

### Example 1: DeepSeek R1 on Consumer GPU

```yaml
deepseek-r1-budget:
  region: us-east-1
  type: g5.xlarge  # 1x A10G (24GB)
  on-demand: 0     # All spot
  hosts:
    - deepseek-budget.domain.com
  model_config:
    api_name: deepseek-r1
    model_repo: unsloth/DeepSeek-R1-0528-Qwen3-8B-GGUF
    model_pattern: "*Q4_0.gguf"
    model_file: DeepSeek-R1-0528-Qwen3-8B-Q4_0.gguf
    chat_template_url: https://huggingface.co/unsloth/DeepSeek-R1/raw/main/chat_template.jinja
    ctx_size: 8192
    gpu_layers: 99
```

### Example 2: Kimi K2 on H200 Cluster

```yaml
kimi-k2-production:
  region: us-west-2
  type: p5e.48xlarge  # 8x H200 (1280GB)
  on-demand: 1        # 1 stable + rest spot
  hosts:
    - kimi-01.domain.com
    - kimi-02.domain.com
    - kimi-03.domain.com
  model_config:
    api_name: kimi-k2
    model_repo: unsloth/Kimi-K2-Instruct-GGUF
    model_pattern: "Q8_0/*"
    model_file: Q8_0/Kimi-K2-Instruct-Q8_0-00001-of-00023.gguf
    chat_template_url: https://huggingface.co/unsloth/Kimi-K2-Instruct/raw/main/chat_template.jinja
    ctx_size: 32768
    parallel: 8
    cont_batching: true
    flash_attn: true
    mlock: true
```

### Example 3: Multi-Region Deployment

```yaml
# Europe
llama3-eu:
  region: eu-west-1
  type: p5en.48xlarge
  on-demand: 1
  hosts:
    - llama-eu-01.domain.com
    - llama-eu-02.domain.com
  model_config:
    api_name: llama3-70b
    model_repo: meta-llama/Llama-3-70B-Instruct-GGUF
    model_pattern: "*Q4_K_M.gguf"
    model_file: llama-3-70b-instruct-q4_k_m.gguf
    hf_token: ${HF_TOKEN}

# Asia
llama3-asia:
  region: ap-southeast-1
  type: p5.48xlarge
  on-demand: 1
  hosts:
    - llama-asia-01.domain.com
  model_config:
    # Same as above
```

## 🙏 Credits

This project builds upon:
- [llama.cpp](https://github.com/ggml-org/llama.cpp) - High-performance inference
- [Pulumi](https://www.pulumi.com/) - Infrastructure as Code
- [Traefik](https://traefik.io/) - Reverse proxy and load balancer
- [Unsloth](https://github.com/unslothai/unsloth) - Optimized model quantizations
- The HuggingFace community

## 📄 License

BSD 3-Clause License - See LICENSE file for details
