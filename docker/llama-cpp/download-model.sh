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
