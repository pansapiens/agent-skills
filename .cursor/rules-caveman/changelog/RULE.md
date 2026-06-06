---
description: Guidelines for maintaining CHANGELOG.md with proper categorization and versioning
alwaysApply: false
---

# CHANGELOG.md

If CHANGELOG.md exists, update with notable features/fixes after implementation.
- Categories:
  - `Added` for new features.
  - `Changed` for changes in existing functionality.
  - `Deprecated` for soon-to-be removed features.
  - `Removed` for now removed features.
  - `Fixed` for bug fixes.
  - `Security` for vulnerabilities.
- For `[Unreleased]`, do not keep history of intermediate/reverted changes. Only document net changes relative to last release. OK to edit/delete in `[Unreleased]`.

Concise bullets. No implementation details.
