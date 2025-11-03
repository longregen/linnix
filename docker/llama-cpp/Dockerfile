# Dockerfile for llama.cpp server with Linnix 3B model
# Optimized for CPU inference

FROM debian:bookworm-slim AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    curl \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Clone llama.cpp (pinned to stable version)
WORKDIR /build
RUN git clone https://github.com/ggerganov/llama.cpp.git && \
    cd llama.cpp && \
    git checkout b4313  # Pin to known good version (Dec 2024)

# Build llama.cpp server (CPU-only, optimized)
WORKDIR /build/llama.cpp
RUN make -j$(nproc) llama-server

# Runtime stage
FROM debian:bookworm-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy llama-server binary
COPY --from=builder /build/llama.cpp/llama-server /usr/local/bin/

# Create model directory
RUN mkdir -p /models

# Download Linnix 3B demo model
# Note: In production, this would download from GitHub releases or S3
# For now, we'll expect it to be mounted as a volume
WORKDIR /models

# Add download script
COPY <<'EOF' /usr/local/bin/download-model.sh
#!/bin/bash
set -e

MODEL_PATH="/models/linnix-3b-distilled-q5_k_m.gguf"
MODEL_URL="${LINNIX_MODEL_URL:-https://github.com/linnix-os/linnix/releases/download/v0.1.0/linnix-3b-distilled-q5_k_m.gguf}"

if [ ! -f "$MODEL_PATH" ]; then
    echo "📥 Downloading Linnix 3B model (2.1GB)..."
    echo "   This may take a few minutes..."
    
    if command -v wget &> /dev/null; then
        wget -q --show-progress "$MODEL_URL" -O "$MODEL_PATH" || {
            echo "❌ Download failed. Please check your internet connection."
            exit 1
        }
    elif command -v curl &> /dev/null; then
        curl -L --progress-bar "$MODEL_URL" -o "$MODEL_PATH" || {
            echo "❌ Download failed. Please check your internet connection."
            exit 1
        }
    else
        echo "❌ Neither wget nor curl found. Cannot download model."
        exit 1
    fi
    
    echo "✅ Model downloaded successfully!"
else
    echo "✅ Model already present at $MODEL_PATH"
fi
EOF

RUN chmod +x /usr/local/bin/download-model.sh

# Expose llama.cpp server port
EXPOSE 8090

# Health check
HEALTHCHECK --interval=15s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8090/health || exit 1

# Entry point: download model if needed, then start server
ENTRYPOINT ["/bin/bash", "-c", "/usr/local/bin/download-model.sh && exec llama-server \"$@\"", "--"]

# Default args (can be overridden in docker-compose)
CMD ["-m", "/models/linnix-3b-distilled-q5_k_m.gguf", \
     "--host", "0.0.0.0", \
     "--port", "8090", \
     "--ctx-size", "4096", \
     "-t", "8"]
