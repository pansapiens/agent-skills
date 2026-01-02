---
description: Docker and docker compose best practices including Dockerfile optimizations and package management
alwaysApply: false
---

# Docker

- Use `docker compose` not `docker-compose`. 
- Don't include a "version" at the top of docker-compose files. 
- If using apt-get in a Dockerfile, include ENV `DEBIAN_FRONTEND=noninteractive`, and use best-practises to clean `/var/lib/apt/lists/`
- When using `pip install`, include `--no-cache-dir` and the environment variable `ENV PIP_BREAK_SYSTEM_PACKAGES=1`

