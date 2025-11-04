#!/bin/bash
# Quick setup script for LLM integration testing

set -e

echo "🚀 Setting up LLM integration for Linnix..."
echo

# Create models directory
mkdir -p models
cd models

# Download TinyLlama model if not present
MODEL_FILE="tinyllama-1.1b-chat-v1.0.Q5_K_M.gguf"
MODEL_URL="https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/$MODEL_FILE"

if [ -f "$MODEL_FILE" ]; then
    echo "✅ Model already downloaded: $MODEL_FILE"
    ls -lh "$MODEL_FILE"
else
    echo "📥 Downloading TinyLlama model (750MB)..."
    echo "   From: $MODEL_URL"
    echo "   This may take 2-5 minutes..."
    echo
    
    if command -v wget &> /dev/null; then
        wget --show-progress "$MODEL_URL"
    elif command -v curl &> /dev/null; then
        curl -L --progress-bar "$MODEL_URL" -o "$MODEL_FILE"
    else
        echo "❌ Neither wget nor curl found. Please install one and try again."
        exit 1
    fi
    
    echo
    echo "✅ Model downloaded successfully!"
    ls -lh "$MODEL_FILE"
fi

cd ..

echo
echo "🐳 Starting Linnix with LLM integration..."
sudo docker-compose -f docker-compose.yml -f docker-compose.llm.yml up -d

echo
echo "⏳ Waiting for services to be healthy..."
sleep 10

echo
echo "📊 Service status:"
sudo docker-compose ps

echo
echo "✅ Setup complete!"
echo
echo "Test endpoints:"
echo "  - Cognitod health: curl http://localhost:3000/healthz"
echo "  - LLM health:      curl http://localhost:8090/health"
echo "  - Get insights:    curl http://localhost:3000/insights | jq"
echo
echo "View logs:"
echo "  docker-compose logs -f"
