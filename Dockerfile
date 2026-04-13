FROM --platform=linux/amd64 nvidia/cuda:12.4.1-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_NO_CACHE_DIR=1

# System dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip git curl ffmpeg ca-certificates patch \
    libgl1 libglib2.0-0 fonts-dejavu-core \
    && rm -rf /var/lib/apt/lists/*

# Install Latest Torch (2026 Stack)
RUN pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124

# ComfyUI
WORKDIR /comfyui
RUN git clone https://github.com/comfyanonymous/ComfyUI.git .

# Custom Nodes for Wan 2.6
RUN git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git custom_nodes/ComfyUI-VideoHelperSuite \
 && git clone https://github.com/kijai/ComfyUI-KJNodes.git custom_nodes/ComfyUI-KJNodes \
 && git clone https://github.com/kijai/ComfyUI-WanVideoWrapper.git custom_nodes/ComfyUI-WanVideoWrapper

# Install node dependencies
RUN for NODE in /comfyui/custom_nodes/*/requirements.txt; do \
    if [ -f "$NODE" ]; then pip3 install -r "$NODE"; fi; \
done

# App Layer
WORKDIR /app
COPY requirements.txt .
RUN pip3 install -r requirements.txt

COPY . .

# Ensure entrypoint script is executable
RUN chmod +x /app/entrypoint.sh

CMD ["/app/entrypoint.sh"]
