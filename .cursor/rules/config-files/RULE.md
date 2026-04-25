---
description: Preferences for implementing configuration file support in apps
alwaysApply: false
---

# Config files

- By default, prefer using TOML as a config file format
- Support config auto-detected in the current working directory, and standard system paths like ~/.config/{app_name}/config.toml
- For determining default config file paths, use the [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir/latest/). Use the `platformdirs` package to achive this in Python.
- Support -c / --config commandline options to specify a config file path explicity.
- Ideally, every config file variable can be overriden by a corresponding environment variable and a commandline variable, eg for the variable 'foo.bar', the env var $APPNAME_FOO_BAR, or the --foo-bar commandline option would override.
- Config precedence should be:
  1. Commandline arguments
  2. Environment variables (typically UPPERCASE and prefixed with APPNAME_)
  3. Config file in current working directory
  4. User config file
  5. System config file
  6. Default values
- Allow environment variables to be used in config files, eg `${MY_VAR}`.