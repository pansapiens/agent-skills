---
description: Guidelines for managing environment variables and .env files following 12 factor app principles
alwaysApply: false
---

# .env files (12 factor app)

This applies to web services in particular.

- Use a .env file for web services and provide a .env.example
- When new environment variables are added to the codebase, ensure they are also added to .env.example
- Ensure .env is added to .gitignore
- NEVER delete the existing .env file, even if you cannot see it

