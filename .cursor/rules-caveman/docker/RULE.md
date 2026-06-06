---
description: Docker and docker compose best practices including Dockerfile optimizations and package management
alwaysApply: false
---

# Docker

- Use `docker compose`, not `docker-compose`.
- No "version" field in docker-compose files.
- If using `apt-get`, set `ENV DEBIAN_FRONTEND=noninteractive` and clean `/var/lib/apt/lists/`.
- If using `pip install`, use `--no-cache-dir` and set `ENV PIP_BREAK_SYSTEM_PACKAGES=1`.
