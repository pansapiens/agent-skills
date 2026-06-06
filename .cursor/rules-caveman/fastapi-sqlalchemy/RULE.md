---
description: FastAPI and SQLAlchemy best practices including async patterns, migrations, and schema management
alwaysApply: false
---

# FastAPI and SQLAlchemy

- Use async.
- Use alembic for Postgres migrations.
- Update Pydantic schema + alembic migrations when modifying models.
- If editing migrations, provide alembic command. Early dev: can edit initial migration + provide SQL to update dev DB. Ask preference.
