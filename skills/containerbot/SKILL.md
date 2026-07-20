---
name: containerbot
description: Create Dockerfiles for GitHub repos. Containerize apps or troubleshoot Docker build failures.
compatibility: Requires docker, git, python3, and internet access for pulling base images and cloning repositories.
---

# Containerbot

Generate optimised Dockerfiles for GitHub repositories by analysing their structure, detecting technologies, and following Docker best practices.

## When to Use This Skill

Use this skill when you see:
- "Create a Dockerfile for a GitHub repo"
- "Containerize this application"
- "Docker build is failing"
- "Help me build a container image"

## Workflow

1. **Reconnaissance** - Analyse the repository structure and detect technologies
2. **Generate .dockerignore** - Create exclusion rules for build efficiency
3. **Generate Dockerfile** - Create an optimised Dockerfile based on detected stack
4. **Build and Test** - Validate the image builds and runs correctly
5. **Refine** - Fix any build or runtime failures

## Phase 1: Repository Reconnaissance

### Current state and user questions

- If the user asks for a Dockerfile for an already cloned working copy, 
look in `.git/config` for the remote URL and use that to determine the repository url 
  (we will need this to to `RUN git clone` in the Dockerfile).
- If you cannot determine the repository url, ask the user to provide it
- If there is no local copy of the repository, `git clone` it first to allow analysis.

Analyse the repository to understand its technology stack:

### File Tree Analysis
- Walk the repository, skipping `.git/` and hidden files
- Note the directory structure and key files

### Technology Detection
Detect and **quantify** the technology stack (e.g., "Python: 80%, JS: 20%"):

- Check for dependency files (see `references/tech-detection.md`)
- Analyse file extensions to calculate usage percentages
- The dominant technology drives base image selection

### README Extraction
- Find README files and extract installation/build instructions
- Look for sections: Installation, Setup, Building, Usage, Getting Started

### Existing Dockerfile Check
Check for existing Dockerfiles in:
- Root directory
- `docker/`, `dockerfiles/`, `.docker/`, `.devops/`, `.gitops/`

If a working Dockerfile exists, use it as a starting point or return it directly.

### Monorepo Detection
If multiple Dockerfiles are found, flag as a monorepo and ask which component to containerise.

## Phase 2: Dockerfile Generation

### Base Image Selection
Map the dominant technology to an optimal base image:

| Technology | Base Image |
|------------|------------|
| Python (pip) | `python:3.x-slim` |
| Python (conda) | `continuumio/miniconda3` or `mambaorg/micromamba` |
| Node.js | `node:lts-slim` |
| Go | `golang:1.x-alpine` or `golang:1.x` |
| Rust | `rust:1.x-slim` |
| Ruby | `ruby:3.x-slim` |
| Java (Maven) | `maven:3-eclipse-temurin-21` |
| Java (Gradle) | `gradle:jdk21` |
| PHP | `php:8.x-fpm` or `php:8.x-cli` |

For mixed technologies, or cases where many system packages are needed, using an `ubuntu`, `debian` or `alpine` image may be preferable.

### Dockerfile Structure

```dockerfile
# Build like:
#  docker buildx build -t image-name -f Dockerfile --build-arg GIT_REF=main .
#

# Metadata
ARG GIT_REPO=https://github.com/owner/repo.git
ARG GIT_REF=main

FROM <base-image>

LABEL org.opencontainers.image.source="${GIT_REPO}"
LABEL org.opencontainers.image.description="<free text description of the container>"
LABEL org.opencontainers.image.licenses="<SPDX-license-identifier>"

# System dependencies (combine into single RUN)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    <other-deps> \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repository (works with branch, tag, or commit hash)
RUN git clone ${GIT_REPO} . && git checkout ${GIT_REF} 

# Install dependencies (before copying code for caching)
# For Python:
RUN pip install --no-cache-dir -r requirements.txt
# Or with uv:
RUN pip install uv && uv pip install --system -r requirements.txt

# For Node:
RUN npm ci --only=production

# For conda (use mamba for speed):
RUN mamba env update -n base -f environment.yml && mamba clean -a -y

# Set up environment
ENV PATH="/app:${PATH}"

# Expose ports if needed
EXPOSE 8000

# Entry point / command (choose one based on application type)
# For persistent services (single executable):
ENTRYPOINT ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
# For CLI tools or multi-binary containers:
CMD ["python", "main.py", "--help"]
```

### Key Guidelines

- **Use `ARG` for repo/branch** - Makes the Dockerfile reusable
- **Use `RUN git clone`** - AVOID using `COPY` for the source code, p
- **Prefer** including short scripts (eg `entrypoint.sh`) as heredocs rather than external files.
- **`/app` as WORKDIR** - Standard convention
- **Dependencies before code** - Optimises layer caching
- **Use cache mounts** for package installs where possible (eg `--mount=type=cache,target=/root/.cache/pip`)
- **Use `mamba`/`uv`** - Faster than conda/pip
- **Multi-stage builds** - Use for compiled languages or when build deps aren't needed at runtime; avoid for simple interpreted apps where they add unnecessary complexity
- **Limit layers** - Combine related `RUN` instructions with `&&`
- **No unnecessary packages** - Only install what's needed
- **Add LABELs** - Require annotations supported by GHCR (source repo, description, and licenses) as well as other relevant OCI annotations.
- **Include the docker build command used** - as a comment at the top of the Dockerfile: `# Build like: docker buildx build -t image-name -f Dockerfile --build-arg GIT_REF=main .`

### CMD vs ENTRYPOINT

Determine if this is a persistent service or a CLI tool:

**Use ENTRYPOINT for persistent services:**
- Web servers, daemons, background workers
- Single executable that runs continuously
- Container acts as that specific service
- Optional commandline options that may be overridden by the user should be in CMD
- Example: 
  ```
  ENTRYPOINT ["uvicorn", "app:app"]
  CMD ["--host", "0.0.0.0", "--port", "8000"]
  ```

**Use CMD for CLI tools or multi-binary containers:**
- Command-line utilities, batch processors
- Containers with multiple executables the user might run
- Allows users to override or pass arguments easily
- Example: `CMD ["mytool", "--help"]`

### Security Considerations
See `references/security.md` for details:
- Run as non-root user where possible
- Don't bake secrets into images
- Pin base image versions

## Phase 2.1: OCI Image Spec Annotations and Internal Image Documentation

### OCI Image Spec annotations

Where practical, include [OCI Image Spec annotations](https://github.com/opencontainers/image-spec/blob/main/annotations.md) as described in `references/oci-annotations.md`.

You MUST always include the annotations supported by GitHub Container Registry (ghcr.io) in the Dockerfile as `LABEL` instructions:
- `org.opencontainers.image.source`: The URL of the repository associated with the package (e.g. `"${GIT_REPO}"`).
- `org.opencontainers.image.description`: A free-text, text-only description of the container, limited to 512 characters.
- `org.opencontainers.image.licenses`: An SPDX license identifier such as "MIT", limited to 256 characters.

### Internal image documentation

We should create a `/README.md` file in the root of the repository that contains the following information:
- The URL to the original repository ($GIT_REPO), including the branch/tag/commit hash ($GIT_REF)
- The purpose / short description of the image
- Instructions for any external data that need to be downloaded and mounted inside the container
- Further usage examples of the image, including any typical `-p PORT:PORT`, `-v $(pwd)/data:/data` and `-e ENV_VAR=value` options

This may be generated inline in the Dockerfile, or if large, as an extra file like:  `COPY README.container.md /README.md`.

## Phase 2.5: .dockerignore Generation

Generate a `.dockerignore` file alongside the Dockerfile - see [the .dockerignore example](assets/dockerignore.example).

Adjust based on the detected technology stack.

## Phase 3: Build Testing and Refinement

After generating the Dockerfile, attempt to build it, eg:

```bash
docker buildx build -t image-name -f Dockerfile --build-arg  GIT_REPO=https://github.com/owner/repo.git --build-arg GIT_REF=main .
```

The build can take a very long time - wait, be patient, set long timeouts and always allow the build to finish. 

- ALWAYS wait for the build to finish before continuing, even if it takes hours. 
- DO NOT skip ahead to the next phase until the build has actually completed. 
- NEVER run commands to indiscriminately 'kill all running containers' - there may be other containers running that are not part of the build process. 
- NEVER indiscriminately prune all cached docker images.

### Build Failure Analysis

If the build fails, analyse the error systematically:

1. **Read the full error message**
2. **Identify the failing layer/instruction**
3. **Determine the root cause**

Common fixes (see `references/docker-best-practices.md`):

| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| Package not found | Missing system deps | Add `build-essential`, `curl`, `git`, etc. |
| Version conflict | Pinned version unavailable | Unpin or use different version |
| Permission denied | File ownership | Check `WORKDIR`, use `chmod` |
| Command not found | Missing PATH | Add `ENV PATH=...` |
| SSL/TLS errors | Missing certs | Install `ca-certificates` |
| Python build fails | Missing headers | Install `python3-dev`, `libffi-dev`, `libssl-dev` |

### Refinement Loop
1. Analyse the error
2. Identify the fix
3. Update the Dockerfile
4. Rebuild and test
5. Repeat until successful

## Phase 4: Functionality Testing

Once the image builds, test that it runs correctly:

### Determine Test Commands
Based on the application type:
- **CLI tools**: `docker run test-image --help` or `--version`
- **Web services**: `docker run -p 8000:8000 test-image` then check health endpoint
- **Scripts**: `docker run test-image` (run default command)

### Runtime Failure Analysis

If the container fails to run:

| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| Exec format error | Wrong architecture | Use correct base image |
| No such file | Wrong WORKDIR or PATH | Check paths, add to PATH |
| Permission denied | Non-root user issues | Adjust file permissions or USER |
| Port already in use | Conflicting port | Use different host port |
| Module not found | Dependencies not installed | Check install step |

### Verify Functionality
- Check that the main command works
- Verify any exposed ports are accessible
- Test with sample input if applicable
- If required, loop back to "Phase 3: Dockerfile Generation" and refine the Dockerfile based on the test results

## Phase 5: Final Review

Once the build is successful and has been shown to be functional, do a final review of the Dockerfile and OCI labels to ensure they are correct.

- Ensure the OCI LABELs, including `org.opencontainers.image.usage`, are consistent with the working example from functionality testing.
- Ensure the `/README.md` examples are correct based on the functionality testing.

If any changes are made, repeat the build and test process.

## Reference Files

- `references/docker-best-practices.md` - Layer optimisation, caching, cache cleaning
- `references/tech-detection.md` - Dependency files, extensions, confidence scoring
- `references/oci-annotations.md` - OCI Image Spec annotations
- `references/security.md` - Non-root users, secrets, base image security

## Scripts

- `scripts/get_docker_image_digest.sh [--platform <platform>] <image>` - Get the SHA256 digest of a Docker image for Dockerfile pinning or OCI labels. Supports `--platform linux/arm64` etc. Run with `--help` for usage.

## Assets

- `assets/dockerignore.example` - Template .dockerignore to copy and adapt for the target repository.
