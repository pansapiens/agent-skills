#!/usr/bin/env bash
# buzz.sh - run the buzz CLI as a specific agent identity.
#
# Usage: buzz.sh <env-file> [buzz args...]
#
# The env file must define BUZZ_RELAY_URL and BUZZ_PRIVATE_KEY (hex or nsec),
# and optionally BUZZ_AUTH_TAG. It is sourced with `set -a` so the variables
# reach the CLI; values are never printed.
set -euo pipefail

env_file="${1:?usage: buzz.sh <env-file> [buzz args...]}"
[[ $# -ge 2 ]] || { echo "usage: buzz.sh <env-file> [buzz args...]" >&2; exit 64; }
shift

if [[ ! -f "$env_file" ]]; then
  echo "buzz.sh: env file not found: $env_file" >&2
  exit 66
fi

if command -v buzz >/dev/null 2>&1; then
  BUZZ_BIN="$(command -v buzz)"
elif [[ -x "$HOME/.local/bin/buzz" ]]; then
  BUZZ_BIN="$HOME/.local/bin/buzz"
else
  echo "buzz.sh: 'buzz' CLI not found on PATH or ~/.local/bin" >&2
  exit 69
fi

set -a
# shellcheck disable=SC1090
. "$env_file"
set +a

exec "$BUZZ_BIN" "$@"
