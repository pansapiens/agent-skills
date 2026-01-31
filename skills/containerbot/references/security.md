# Docker Security Best Practices

Security guidelines for Dockerfile generation.

## Running as Non-Root User

Containers should run as non-root users to limit the impact of container escapes.

### Creating a User

**Debian/Ubuntu:**
```dockerfile
RUN groupadd -r appgroup && useradd -r -g appgroup appuser
USER appuser
```

**Alpine:**
```dockerfile
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser
```

**With explicit UID/GID (recommended):**
```dockerfile
# Use UID/GID above 10000 to avoid overlap with host system users
RUN groupadd -g 10001 appgroup && \
    useradd -u 10000 -g appgroup -s /bin/false appuser
USER appuser:appgroup
```

### Complete Example

```dockerfile
FROM python:3.12-slim

WORKDIR /app

# Install dependencies as root
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Create non-root user
RUN groupadd -g 10001 appgroup && \
    useradd -u 10000 -g appgroup -s /bin/false appuser && \
    chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser

COPY --chown=appuser:appgroup . .

CMD ["python", "app.py"]
```

### When Root is Required

Some operations require root:
- Binding to ports below 1024 (use higher ports instead)
- Installing system packages (do before `USER` directive)
- Modifying system files

Pattern: Run setup as root, switch to non-root for runtime.

## Secrets Handling

Never bake secrets into Docker images.

### What NOT to Do

```dockerfile
# BAD: Secret in image layer
ENV API_KEY=secret123

# BAD: Secret in build command
RUN echo "password" > /app/config

# BAD: Copying secrets file
COPY .env /app/.env
```

### Correct Approaches

**1. Runtime Environment Variables:**
```dockerfile
# Dockerfile - no secrets
ENV API_KEY=""

# Runtime - pass secrets via env file (not on command line which exposes to `ps`)
docker run --env-file .env myimage
```

**2. Docker Secrets (Swarm/Compose):**
```yaml
# docker-compose.yml
services:
  app:
    secrets:
      - db_password
secrets:
  db_password:
    file: ./secrets/db_password.txt
```

**3. Build-time Secrets (BuildKit):**

Secret mounts expose secrets only during build, not persisted in the final image.

```dockerfile
# Mount secret as file (default: /run/secrets/<id>)
RUN --mount=type=secret,id=api_key \
    cat /run/secrets/api_key

# Mount secret as environment variable
RUN --mount=type=secret,id=api_key,env=API_KEY \
    echo "Key available as $API_KEY"

# Mount to custom path
RUN --mount=type=secret,id=aws,target=/root/.aws/credentials \
    aws s3 cp ...
```

Build command:
```bash
# From file
docker build --secret id=api_key,src=./secrets/api_key.txt .

# From environment variable
docker build --secret id=API_TOKEN .
```

**4. SSH Mounts (for private Git repos):**
```dockerfile
# Clone private repo using SSH
RUN --mount=type=ssh git clone git@github.com:org/private-repo.git
```

Build command:
```bash
docker build --ssh default .
```

**5. Git Authentication (private remote contexts):**
```bash
# Build from private repo using GIT_AUTH_TOKEN
GIT_AUTH_TOKEN=$(cat token.txt) docker build \
    --secret id=GIT_AUTH_TOKEN \
    https://github.com/org/private-repo.git
```

**6. Environment File at Runtime:**
```bash
# Pass env file at runtime (not baked into image)
docker run --env-file .env myimage
```

### Private Dependency Registries

**npm (private registry):**
```dockerfile
# Use BuildKit secret for .npmrc
RUN --mount=type=secret,id=npmrc,target=/root/.npmrc \
    npm ci
```

**pip (private PyPI):**
```dockerfile
# Pass credentials via build arg (less secure) or secret
ARG PIP_INDEX_URL
RUN pip install --no-cache-dir -r requirements.txt
```

## Base Image Security

### Use Official Images

Prefer images from:
- Docker Official Images (verified badge)
- Verified Publishers
- Docker-Sponsored Open Source

```dockerfile
# Good: Official image
FROM python:3.12-slim

# Risky: Unknown publisher
FROM randomuser/python:latest
```

### Pin Versions

**Tag pinning (recommended minimum):**
```dockerfile
# Good: Specific version
FROM python:3.12-slim

# Bad: Floating tag
FROM python:latest
```

**Digest pinning (most secure):**
```dockerfile
# Maximum reproducibility and security
FROM python:3.12-slim@sha256:abcd1234...
```

To get a digest:
```bash
docker pull python:3.12-slim
docker inspect python:3.12-slim --format='{{.RepoDigests}}'
```

### Keep Images Updated

Rebuild regularly to get security patches:
```bash
docker build --pull --no-cache -t myimage .
```

## Minimal Images

Reduce attack surface by minimizing image contents.

### Remove Unnecessary Tools

```dockerfile
# Install build deps, use them, remove them
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && pip install --no-cache-dir -r requirements.txt \
    && apt-get purge -y build-essential \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*
```

### Use Slim/Minimal Variants

| Base | Slim Variant |
|------|--------------|
| `python:3.12` | `python:3.12-slim` |
| `node:20` | `node:20-slim` |
| `debian:bookworm` | `debian:bookworm-slim` |

### Distroless Images (Advanced)

For maximum security (no shell, no package manager):

```dockerfile
FROM python:3.12-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

FROM gcr.io/distroless/python3-debian12
COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY . /app
WORKDIR /app
CMD ["app.py"]
```

Note: Distroless images have no shell, making debugging harder.

## File Permissions and Ownership

### Set Correct Ownership

```dockerfile
# Copy with ownership
COPY --chown=appuser:appgroup src/ /app/src/

# Or change after copy
COPY src/ /app/src/
RUN chown -R appuser:appgroup /app/src/
```

### Avoid World-Writable Files

```dockerfile
# Set restrictive permissions
RUN chmod 755 /app && \
    chmod 644 /app/config.yml && \
    chmod 500 /app/entrypoint.sh
```

### Protect Sensitive Files

```dockerfile
# Configuration with secrets should be read-only
RUN chmod 400 /app/secrets.yml
```

## Additional Security Measures

### Read-Only Filesystem

Run containers with read-only root filesystem:
```bash
docker run --read-only myimage
```

Prepare for this in Dockerfile:
```dockerfile
# Create writable directories for temp files
RUN mkdir -p /tmp /var/tmp && chmod 1777 /tmp /var/tmp
VOLUME ["/tmp"]
```

### Drop Capabilities

Run with minimal Linux capabilities:
```bash
docker run --cap-drop=ALL --cap-add=NET_BIND_SERVICE myimage
```

### Security Scanning

Before deploying, scan images for vulnerabilities:
```bash
docker scout cves myimage
# or
trivy image myimage
```

## Security Checklist

Before finalising a Dockerfile:

- [ ] Non-root user for runtime
- [ ] No secrets in image layers
- [ ] Official/verified base image
- [ ] Base image version pinned
- [ ] Unnecessary packages removed
- [ ] Minimal base image variant used
- [ ] File permissions are restrictive
- [ ] Sensitive files excluded via .dockerignore
