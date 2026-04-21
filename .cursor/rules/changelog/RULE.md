---
description: Guidelines for maintaining CHANGELOG.md with proper categorization and versioning
alwaysApply: false
---

# CHANGELOG.md

If there is a CHANGELOG.md file, update it with any notable features or bug fixes once these have been successfully implemented.
- When updating the `CHANGELOG.md`, add notable features and fixes, with the following categories:
  - `Added` for new features.
  - `Changed` for changes in existing functionality.
  - `Deprecated` for soon-to-be removed features.
  - `Removed` for now removed features.
  - `Fixed` for any bug fixes.
  - `Security` in case of vulnerabilities.
- For `[Unreleased]`, we don't need to maintain a history of every intermediate change if a change was reverted or overrides a previous unreleased change (eg 'changed to use packageX version 1, then changed to use packageX version 2') - just document the changes relative to the last versioned release to the current state. You may update or remove text from the `[Unreleased]` section as required - you don't always need to append only.

Keep dot points concise - list the change but don't elaborate on implementation detail.