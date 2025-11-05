# Linnix Scripts Documentation

This directory contains essential scripts for setup, deployment, testing, and release management.

## 📁 Script Categories

### 🚀 Setup & Quickstart (Root Directory)

| Script | Purpose | Usage |
|--------|---------|-------|
| `quickstart.sh` | Complete automated setup with health checks | `./quickstart.sh` |

**Description**: One-command setup that gets Linnix running in under 5 minutes. Checks prerequisites, downloads model, starts services, and validates everything works.

---

### 🐋 Docker & Container Management (Root Directory)

| Script | Purpose | Usage |
|--------|---------|-------|
| `build-and-push-images.sh` | Build and optionally push Docker images to any registry | `./build-and-push-images.sh [registry]` |

**Examples**:
```bash
# Build for Docker Hub (default)
./build-and-push-images.sh

# Build for GitHub Container Registry
./build-and-push-images.sh ghcr.io/linnix-os
```

**Description**: Universal Docker image builder supporting multiple registries. Builds cognitod, linnix-cli, and linnix-reasoner images with optional push prompt.

---

### 🎬 Demo & Testing (Root Directory)

| Script | Purpose | Usage |
|--------|---------|-------|
| `demo-workload.sh` | Generate realistic system activity for demos | `./demo-workload.sh` |
| `quick-test.sh` | Validate all running services with detailed output | `./quick-test.sh` |

**Description**: Scripts for demonstrating features and testing system behavior.

---

### 📦 Release & CI/CD (scripts/)

| Script | Purpose | Usage |
|--------|---------|-------|
| `release.sh` | Create GitHub release with artifacts | `scripts/release.sh` |

**Description**: Scripts for creating releases and publishing artifacts.

---

### 🔧 Special Purpose (docker/)

| Script | Purpose | Usage |
|--------|---------|-------|
| `docker/llama-cpp/download-model.sh` | Download model inside Docker container | Called by Dockerfile |

**Description**: Scripts embedded in Docker images for runtime operations.

---

## 🎯 Common Workflows

### First-Time Setup
```bash
# Complete automated setup - everything you need
./quickstart.sh
```

### Running Demos
```bash
# Generate system activity
./demo-workload.sh

# Validate everything works
./quick-test.sh
```

### Docker Development
```bash
# Build for Docker Hub
./build-and-push-images.sh

# Build for GitHub Container Registry
./build-and-push-images.sh ghcr.io/linnix-os

# Build for custom registry
./build-and-push-images.sh myregistry.com/linnix
```

### Creating a Release
```bash
# Build, tag, and publish release
scripts/release.sh
```

---

## 📝 Script Naming Conventions

- **`setup-*.sh`** - Initial setup and configuration
- **`test-*.sh`** - Testing and validation
- **`demo-*.sh`** or `demo_*.sh` - Demonstration workloads
- **`build-*.sh`** - Docker image building
- **`push-*.sh`** - Registry publishing
- **`*_to_*.sh`** - Conversion or migration utilities
- **`*_model.sh`** - Model-specific operations

---

## 🔒 Requirements

### System Requirements
- **Linux kernel 5.0+** (for eBPF)
- **Docker & Docker Compose**
- **4GB+ RAM** (for AI model)
- **10GB disk space** (for models and images)

### Optional Tools
- **curl/wget** - Model downloads
- **jq** - JSON parsing
- **cargo** - Rust builds (for development)

---

## 🐛 Troubleshooting

### Scripts won't execute
```bash
chmod +x *.sh
chmod +x scripts/*.sh
chmod +x docker/llama-cpp/*.sh
```

### Permission issues
```bash
# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

### Model download fails
```bash
# Manual download
wget https://huggingface.co/parth21shah/linnix-3b-distilled/resolve/main/linnix-3b-distilled-q5_k_m.gguf \
  -O models/linnix-3b-distilled-q5_k_m.gguf
```

### Services won't start
```bash
# Check Docker daemon
sudo systemctl status docker

# Check ports
netstat -tlnp | grep -E '3000|8080|8090'

# View logs
docker-compose logs -f
```

---

## 📚 Additional Documentation

- **Main README**: `../README.md`
- **Docker Setup**: `../DOCKER_QUICKSTART_SUMMARY.md`
- **Release Process**: `../RELEASE_NOTES_v0.1.0.md`
- **eBPF Details**: `../docs/collector.md`
- **Prometheus Integration**: `../docs/prometheus-integration.md`
- **Dataset Pipeline**: `../insight_tool/README.md`

---

## 🤝 Contributing

When adding new scripts:

1. **Choose the right location**:
   - User-facing setup/demo → root directory
   - Development/cloud → `scripts/` subdirectory
   - Container runtime → `docker/*/` subdirectory

2. **Make it executable**: `chmod +x script.sh`

3. **Add header comments**:
   ```bash
   #!/bin/bash
   # Brief description
   # Usage: ./script.sh [args]
   ```

4. **Update this README** with script details

5. **Test thoroughly** before committing

---

**Last Updated**: November 5, 2025  
**Maintainer**: Linnix Team
