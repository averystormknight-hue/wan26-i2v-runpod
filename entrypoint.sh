#!/bin/bash
set -e

echo "🚀 Starting Wan 2.6 I2V (Pickle Edition) entrypoint..."

MODEL_ROOT="/comfyui/models"
LORA_ROOT="/comfyui/models/loras"

# Handle RunPod persistent storage
if [ -d /runpod-volume ]; then
    mkdir -p /runpod-volume/models /runpod-volume/loras
    MODEL_ROOT="/runpod-volume/models"
    LORA_ROOT="/runpod-volume/loras"
    ln -sfn "$MODEL_ROOT" /comfyui/models
    ln -sfn "$LORA_ROOT" /comfyui/models/loras
elif [ -d /workspace ]; then
    mkdir -p /workspace/models /workspace/loras
    MODEL_ROOT="/workspace/models"
    LORA_ROOT="/workspace/loras"
    ln -sfn "$MODEL_ROOT" /comfyui/models
    ln -sfn "$LORA_ROOT" /comfyui/models/loras
fi

# HuggingFace CLI to download weights
if [ "${NOVA_SKIP_MODEL_DOWNLOAD:-0}" != "1" ]; then
    echo "📥 Downloading Wan 2.6 I2V Weights..."
    huggingface-cli download Wan-AI/Wan2.6-I2V-14B --local-dir "$MODEL_ROOT/diffusion_models" --include "*.safetensors"
    huggingface-cli download Wan-AI/Wan-VAE --local-dir "$MODEL_ROOT/vae" --include "*.safetensors"
    huggingface-cli download Wan-AI/Wan-T5-XXL --local-dir "$MODEL_ROOT/text_encoders" --include "*.safetensors"
    huggingface-cli download Wan-AI/Wan-Clip-Vision --local-dir "$MODEL_ROOT/clip_vision" --include "*.safetensors"
fi

# Start ComfyUI in background
python3 /comfyui/main.py --listen 0.0.0.0 --port 8188 --disable-auto-launch &

# Wait for ComfyUI to be ready
echo "⏳ Waiting for ComfyUI..."
until curl -s http://127.0.0.1:8188/system_stats > /dev/null; do
  sleep 2
done
echo "✅ ComfyUI is up!"

# Start RunPod Handler
python3 -u /app/handler.py
