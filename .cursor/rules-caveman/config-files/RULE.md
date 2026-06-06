---
description: Preferences for implementing configuration file support in apps
alwaysApply: false
---

# Config files

- Prefer TOML format.
- Support auto-detect in CWD and system paths like `~/.config/{app_name}/config.toml`.
- Use [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir/latest/) for default paths. Use `platformdirs` in Python.
- Support `-c` / `--config` to set path explicitly.
- Allow override of config variables via env vars and CLI args (e.g. 'foo.bar' → `$APPNAME_FOO_BAR` or `--foo-bar`).
- Precedence:
  1. CLI arguments
  2. Env variables (UPPERCASE, prefix `APPNAME_`)
  3. Config in CWD
  4. User config
  5. System config
  6. Default values
- Support env var expansion in config files, e.g. `${MY_VAR}`.
