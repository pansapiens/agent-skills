---
description: FastAPI and SQLAlchemy best practices including async patterns, migrations, and schema management
alwaysApply: false
---

# FastAPI and SQLAlchemy

- Use async where possible
- Use alembic for migrations when using Postgres
- When modifying models, also ensure to update any associated Pydantic schema and the alembic migrations
- Modifying alembic migrations may involve providing the request alembic command to run. In early non-production development we may instead modify the initial migrations and provide SQL to update the dev database (to prevent unnessecary bloat of migration versions). Ask what would be preferred.

