#!/usr/bin/env bash
# get-bb-wasm.sh - make sure a WebAssembly batari Basic toolchain is available.
#
# Prints the path to the bB directory on stdout (and nothing else):
#     export bB=$(scripts/get-bb-wasm.sh)
#
# Why this exists: from v1.9 the ONLY artifacts batari Basic publishes are
# wasm builds (bB-1.9-wasm.tar.gz). The native binaries are build-from-source.
# The wasm toolchain runs identically on Linux, macOS and Windows with no
# compiler, no lex, and no build step - it just needs wasmtime. That makes it
# the portable option, and it produces byte-identical ROMs to a native build.
#
# Everything is cached outside the skill directory so nothing lands in a git
# working tree. Override the location with BB_CACHE.
set -euo pipefail

CACHE="${BB_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/batari-basic}"
BBDIR="$CACHE/bB"
WASMTIME="$CACHE/wasmtime"

BB_URL="https://github.com/batari-basic/batari-basic/releases/latest/download/bB-1.9-wasm.tar.gz"

have_wasmtime() {
    if [ -n "${BB_WASMTIME:-}" ] && [ -x "${BB_WASMTIME}" ]; then
        echo "$BB_WASMTIME"; return 0
    fi
    if [ -x "$WASMTIME" ]; then echo "$WASMTIME"; return 0; fi
    if command -v wasmtime >/dev/null 2>&1; then command -v wasmtime; return 0; fi
    return 1
}

# --- the bB wasm distribution -------------------------------------------
if [ ! -f "$BBDIR/2600basic.wasm" ]; then
    mkdir -p "$CACHE"
    echo "downloading batari Basic (wasm) -> $BBDIR" >&2
    TARBALL="$CACHE/bB-wasm.tar.gz"
    if ! curl -sfL -o "$TARBALL.part" "$BB_URL"; then
        rm -f "$TARBALL.part"
        echo "get-bb-wasm: download failed: $BB_URL" >&2
        exit 1
    fi
    mv "$TARBALL.part" "$TARBALL"
    # the tarball contains a top-level bB/ directory
    tar xzf "$TARBALL" -C "$CACHE"
    if [ ! -f "$BBDIR/2600basic.wasm" ]; then
        echo "get-bb-wasm: extracted archive has no bB/2600basic.wasm" >&2
        exit 1
    fi
fi

# --- the wasmtime runtime ------------------------------------------------
if ! have_wasmtime >/dev/null; then
    os=$(uname -s)
    arch=$(uname -m)
    case "$os/$arch" in
        Linux/x86_64)  asset="x86_64-linux" ;;
        Linux/aarch64) asset="aarch64-linux" ;;
        Darwin/x86_64) asset="x86_64-macos" ;;
        Darwin/arm64)  asset="aarch64-macos" ;;
        *)
            cat >&2 <<EOF
get-bb-wasm: don't know which wasmtime build fits $os/$arch.
Install it yourself, then re-run:
    curl https://wasmtime.dev/install.sh -sSf | bash
or set BB_WASMTIME=/path/to/wasmtime.
EOF
            exit 1 ;;
    esac

    echo "downloading wasmtime ($asset) -> $WASMTIME" >&2
    # The release tarball unpacks to wasmtime-<ver>-<asset>/wasmtime.
    API="https://api.github.com/repos/bytecodealliance/wasmtime/releases/latest"
    URL=$(curl -sfL "$API" \
        | grep -o "https://[^\"]*wasmtime-v[^\"]*-$asset\.tar\.xz" \
        | head -1) || true
    if [ -z "${URL:-}" ]; then
        echo "get-bb-wasm: could not find a wasmtime $asset asset in the latest release" >&2
        exit 1
    fi
    TMP=$(mktemp -d "$CACHE/wasmtime.XXXXXX")
    if ! curl -sfL -o "$TMP/w.tar.xz" "$URL"; then
        rm -rf "$TMP"
        echo "get-bb-wasm: download failed: $URL" >&2
        exit 1
    fi
    tar xf "$TMP/w.tar.xz" -C "$TMP"
    found=$(find "$TMP" -type f -name wasmtime | head -1)
    if [ -z "$found" ]; then
        rm -rf "$TMP"
        echo "get-bb-wasm: no wasmtime binary inside $URL" >&2
        exit 1
    fi
    chmod +x "$found"
    mv "$found" "$WASMTIME"
    rm -rf "$TMP"
fi

echo "$BBDIR"
