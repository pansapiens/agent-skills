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
ADD https://raw.githubusercontent.com/owner/repo/main/requirements.txt /tmp/
RUN pip install -r /tmp/requirements.txt
# Update CACHE_BUST to force a fresh clone
ARG CACHE_BUST=1
RUN git clone https://github.com/owner/repo.git /app

# Bad: Any code change invalidates dependency cache
ARG CACHE_BUST=1
RUN git clone https://github.com/owner/repo.git /app
RUN pip install -r /app/requirements.txt
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

The point of combining is to stop intermediate cruft (apt lists, build dependencies,
extracted tarballs) being frozen into the image. It does **not** apply to payload that
has to ship anyway: bundling several multi-GB downloads into one `RUN` just creates one
huge, fragile blob. See [Layer Size Limits](#layer-size-limits).

## Dependency Installation and Cache Management

There are two primary approaches to managing package caches:
1. Preferred: **Use Cache Mounts (`--mount=type=cache`)**: Persists package caches across builds to speed up rebuilds. Because the cache mount is not committed to the final image, you **should not** clean up the cache directories (e.g. via `rm -rf`) in the command, as doing so will delete the persistent cache on the host. Requires BuildKit (Docker 23.0+ or `DOCKER_BUILDKIT=1`).
2. Alternative: **Clean Cache Directories**: If not using cache mounts, you **must** clean up the cache directories in the same `RUN` instruction (e.g. `&& rm -rf /var/lib/apt/lists/*`) to prevent them from bloating the final image layers.

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

## Layer Size Limits

**Keep every layer under 5 GB.** Split large downloads or installs across multiple
`RUN` steps rather than combining them.

This cuts against the usual "combine `RUN` instructions" advice, and deliberately so.
Combining exists to stop intermediate cruft (apt lists, build deps) being frozen into
the image. It does not apply to a payload that has to be in the final image anyway -
there, more layers is strictly better:

- **Blob transfers are not resumable within a blob.** One dropped connection
  re-downloads the whole layer. An 8 GB layer turns a transient blip into an 8 GB
  retry, and shows up as `error writing layer: unexpected EOF` or a stalled pull.
- **Registries impose ceilings.** AWS ECR documents a 10 GiB maximum layer size.
  The OCI spec sets no limit, but proxies, CDNs and gateways time out on long
  single-blob transfers well before that.
- **Layers pull in parallel.** One huge layer serialises the pull behind itself.
- **Cache granularity.** Changing one download URL only invalidates its own layer.

```dockerfile
# Good: each model is its own layer, independently retryable
RUN wget -P /models https://example.com/model-a.ckpt   # 2.5 GB
RUN wget -P /models https://example.com/model-b.ckpt   # 2.5 GB
RUN wget -P /models https://example.com/model-c.ckpt   # 2.8 GB

# Bad: one 7.8 GB blob - a dropped connection costs all of it
RUN wget -P /models https://example.com/model-a.ckpt \
    && wget -P /models https://example.com/model-b.ckpt \
    && wget -P /models https://example.com/model-c.ckpt
```

### Measuring layer size

Use `scripts/check_layer_sizes.sh`, which flags anything over the threshold and exits
non-zero so it can gate CI:

```bash
scripts/check_layer_sizes.sh myimage:latest             # local build
scripts/check_layer_sizes.sh --remote ghcr.io/owner/image:tag
scripts/check_layer_sizes.sh --max-gb 2 myimage:latest
```

Or directly:

```bash
# Local image: sizes plus the instruction that created each layer.
docker history --no-trunc --format '{{.Size}}\t{{.CreatedBy}}' myimage:latest
```

**`docker history` reports UNCOMPRESSED sizes; the registry stores and transfers
COMPRESSED blobs.** The compressed number is the one that matters for pull
reliability, so check a pushed image against the manifest:

```bash
docker manifest inspect ghcr.io/owner/image:tag | jq '.layers[].size'
```

For a multi-arch tag that returns an image *index* with no layers of its own - resolve
to a platform manifest first:

```bash
docker manifest inspect ghcr.io/owner/image:tag \
  | jq -r '.manifests[] | select(.platform.architecture=="amd64") | .digest'
docker manifest inspect ghcr.io/owner/image@sha256:<digest> | jq '.layers[].size'
```

To attribute a large layer to the build step that produced it on an image you have not
pulled, zip the manifest's `layers` against the config blob's `history` entries, after
dropping the ones marked `empty_layer` (metadata-only instructions like `ENV`, `ARG`,
`LABEL` and `CMD` produce no layer). The two lists then line up one-to-one.

### The `chmod -R` / `chown -R` copy-up trap

**A recursive `chmod` or `chown` in its own `RUN` re-materialises every file it touches
into that layer**, even when nothing about the file changes. overlayfs copies a file up
on *any* `setattr`, and GNU `chmod` issues the syscall even when the mode already
matches, so there is no "no-op" fast path.

Measured with buildkit on a 150 MB payload:

| Step | Layer size |
| --- | --- |
| create 150 MB file, `chmod` that file in the same `RUN` | 157 MB |
| create 150 MB file, `chmod -R` the whole directory (spanning an earlier layer) | **315 MB** |
| `chmod -R a+rX` that changes no modes at all | **157 MB** |
| read-only `find` over the directory | **0 B** |

A real case: `RUN chmod -R a+rx /models` after 8 GB of model downloads added an 8.10 GB
layer - a byte-for-byte duplicate of the weights - taking the image from 12.6 GB to
20.7 GB and creating the only layer over 5 GB.

The same trap catches the very common "add a non-root user at the end" pattern:

```dockerfile
# Bad: doubles the size of everything under /app
COPY . /app
RUN chown -R app:app /app
```

**Set ownership and permissions in the same step that creates the files**, so the
copy-up lands in the layer that already holds those bytes:

```dockerfile
# COPY: use the built-in flags, no extra layer at all
COPY --chown=app:app --chmod=644 . /app

# Downloads: scope the fix to what this step just created, via a stamp file
RUN touch /tmp/.stamp \
    && wget -P /models https://example.com/model-a.ckpt \
    && find /models -newer /tmp/.stamp -exec chmod a+rX {} + \
    && rm -f /tmp/.stamp

# Creating files directly: set the mode at creation
RUN install -m 0644 build/output.bin /opt/app/output.bin
```

If you want a guarantee that permissions are correct, verify rather than fix. `find`
only reads, so the layer is 0 B and the build still fails loudly:

```dockerfile
RUN bad="$(find /models \( -type f ! -perm -o=r \) -o \( -type d ! -perm -o=x \))"; \
    [ -z "$bad" ] || { echo "not world-readable:"; echo "$bad"; exit 1; }
```

**Use `a+rX`, not `a+rx`.** Capital `X` sets the execute bit on directories only (and on
files that already have one), so data files do not end up spuriously executable.

Note that `-perm -o=r` is GNU `find` syntax and is not supported by BusyBox `find` on
Alpine; use octal `-perm` tests there, or run the check on a Debian-based stage.

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
