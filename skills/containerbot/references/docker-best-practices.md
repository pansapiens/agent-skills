# Docker Best Practices

Detailed optimisation patterns for Dockerfile generation.

## Layer Ordering for Cache Efficiency

Order instructions from least to most frequently changing:

1. **Base image** - Rarely changes
2. **System packages** - Occasional updates
3. **Language runtime setup** - Occasional changes
4. **Dependency files** - Changes with new deps
5. **Install dependencies** - Rebuilds when deps change
6. **Application code** - Changes frequently

```dockerfile
# Good: Dependencies cached separately from code
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .

# Bad: Any code change invalidates dependency cache
COPY . .
RUN pip install -r requirements.txt
```

## Combining RUN Instructions

Combine related commands to reduce layers:

```dockerfile
# Good: Single layer
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Bad: Multiple layers, apt cache persists
RUN apt-get update
RUN apt-get install -y build-essential
RUN apt-get install -y curl
RUN apt-get install -y git
```

## Dependency Installation and Cache Management

Use cache mounts (`--mount=type=cache`) to persist package caches across builds. This speeds up rebuilds even when layers are invalidated. Requires BuildKit (Docker 23.0+ or `DOCKER_BUILDKIT=1`).

### apt (Debian/Ubuntu)
```dockerfile
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends \
    package1 \
    package2
```
Note: `sharing=locked` required as apt needs exclusive access. No need to `rm -rf /var/lib/apt/lists/*` with cache mounts.

### yum/dnf (RHEL/Fedora)
```dockerfile
RUN --mount=type=cache,target=/var/cache/yum \
    yum install -y package1 package2
```

### apk (Alpine)
```dockerfile
RUN apk add --no-cache package1 package2
```
Note: Alpine's `--no-cache` is efficient enough; cache mounts add little benefit.

### pip (Python)
```dockerfile
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install -r requirements.txt
```

### uv (Python - faster)
```dockerfile
RUN --mount=type=cache,target=/root/.cache/uv \
    uv pip install --system -r requirements.txt
```

### npm (Node.js)
```dockerfile
RUN --mount=type=cache,target=/root/.npm \
    npm ci --only=production
```

### conda/mamba
```dockerfile
RUN --mount=type=cache,target=/opt/conda/pkgs \
    mamba install -y package1 package2
```

### Go
```dockerfile
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go build -o /app/binary
```

### Rust (Cargo)
```dockerfile
RUN --mount=type=cache,target=/usr/local/cargo/git/db \
    --mount=type=cache,target=/usr/local/cargo/registry/ \
    --mount=type=cache,target=/app/target/ \
    cargo build --release
```
Note: Copy binary out of cache mount in same RUN if needed in final image.

### Ruby (Bundler)
```dockerfile
RUN --mount=type=cache,target=/root/.gem \
    bundle install
```

### PHP (Composer)
```dockerfile
RUN --mount=type=cache,target=/root/.composer/cache \
    composer install --no-dev
```

### .NET (NuGet)
```dockerfile
RUN --mount=type=cache,target=/root/.nuget/packages \
    dotnet restore
```

### Cache Mount Notes
- Cache mounts are not included in the final image (no size impact)
- Use `sharing=locked` for package managers that need exclusive access (apt, yum)
- Speeds up rebuilds significantly, especially in CI/CD with cold layer caches

## Base Image Selection

### General Guidelines
- Use official images from Docker Hub
- Prefer `-slim` variants over full images
- Alpine is smaller but may have compatibility issues (musl vs glibc)
- Match the base image to your deployment environment

### Size Comparison (approximate)
| Image | Size |
|-------|------|
| `python:3.12` | ~1GB |
| `python:3.12-slim` | ~150MB |
| `python:3.12-alpine` | ~50MB |
| `node:20` | ~1GB |
| `node:20-slim` | ~200MB |
| `node:20-alpine` | ~130MB |

### When to Use Alpine
- Simple applications with no native dependencies
- Go binaries (statically compiled)
- When image size is critical

### When to Avoid Alpine
- Python with C extensions (numpy, pandas, etc.)
- Applications requiring glibc
- When build time matters more than image size

## Avoiding Unnecessary Packages

Only install what you need:

```dockerfile
# Good: Minimal install
RUN apt-get install -y --no-install-recommends \
    python3 \
    python3-pip

# Bad: Includes unnecessary recommended packages
RUN apt-get install -y python3 python3-pip

# Bad: Installing "nice to have" packages
RUN apt-get install -y vim nano htop  # Not needed in production
```

### The `--no-install-recommends` Flag
Always use `--no-install-recommends` with apt-get to avoid pulling in optional packages.

## Using LABEL for Metadata

Add metadata labels following OCI conventions:

```dockerfile
LABEL org.opencontainers.image.source="https://github.com/owner/repo"
LABEL org.opencontainers.image.description="Brief description of the image"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.version="1.0.0"
LABEL maintainer="name@example.com"
```

Or combined:
```dockerfile
LABEL org.opencontainers.image.source="https://github.com/owner/repo" \
      org.opencontainers.image.description="Brief description" \
      org.opencontainers.image.licenses="MIT"
```

## Size Optimisation Techniques

### Remove Build Dependencies After Use

**Preferred: Multi-stage build** (cleanest approach)
```dockerfile
FROM python:3.12-slim AS builder
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends build-essential
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --prefix=/install -r requirements.txt

FROM python:3.12-slim
COPY --from=builder /install /usr/local
```

**Alternative: Single-stage with cleanup** (if multi-stage not practical)
```dockerfile
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends build-essential \
    && pip install -r requirements.txt \
    && apt-get purge -y build-essential \
    && apt-get autoremove -y
```
Note: With cache mounts, no need for `rm -rf /var/lib/apt/lists/*`.

### Use .dockerignore
Exclude unnecessary files from the build context:
```
.git
node_modules
__pycache__
*.pyc
.env
```

### Delete Temporary Files in Same Layer
```dockerfile
RUN curl -L https://example.com/file.tar.gz -o /tmp/file.tar.gz \
    && tar -xzf /tmp/file.tar.gz -C /opt \
    && rm /tmp/file.tar.gz
```

## Common Patterns by Technology

### Python Web Service (persistent)
```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
# Use cache mount for faster rebuilds
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install -r requirements.txt
COPY . .
EXPOSE 8000
# Persistent service with single entry point → ENTRYPOINT
ENTRYPOINT ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Node.js Web Service (persistent)
```dockerfile
FROM node:20-slim
WORKDIR /app
COPY package*.json ./
# Use cache mount for faster rebuilds
RUN --mount=type=cache,target=/root/.npm \
    npm ci --only=production
COPY . .
EXPOSE 3000
# Persistent service with single entry point → ENTRYPOINT
ENTRYPOINT ["node", "server.js"]
```

### Go CLI Tool
```dockerfile
FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY go.* ./
# Use cache mounts for module and build caches
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go mod download
COPY . .
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 go build -o /app/binary .

FROM scratch
COPY --from=builder /app/binary /binary
# CLI tool → CMD (allows user to pass args or override)
CMD ["/binary", "--help"]
```

### Rust CLI Tool
```dockerfile
FROM rust:1.75-slim AS builder
WORKDIR /app
COPY Cargo.* ./
RUN mkdir src && echo "fn main() {}" > src/main.rs
# Use cache mounts for cargo registry and build cache
RUN --mount=type=cache,target=/app/target/ \
    --mount=type=cache,target=/usr/local/cargo/git/db \
    --mount=type=cache,target=/usr/local/cargo/registry/ \
    cargo build --release
COPY src ./src
RUN --mount=type=cache,target=/app/target/ \
    --mount=type=cache,target=/usr/local/cargo/git/db \
    --mount=type=cache,target=/usr/local/cargo/registry/ \
    touch src/main.rs && cargo build --release && \
    cp /app/target/release/binary /binary

FROM debian:bookworm-slim
COPY --from=builder /binary /usr/local/bin/binary
# CLI tool → CMD (allows user to pass args or override)
CMD ["binary", "--help"]
```
