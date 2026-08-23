# Installing batari Basic

Two options, and both are fine — pick by what the machine has.

| | wasm (`scripts/get-bb-wasm.sh`) | native (build from source) |
|---|---|---|
| Needs | `wasmtime` (auto-fetched) | gcc, make, flex |
| Install | one command, ~4 s | clone + `make`, ~2 min |
| Platforms | Linux, macOS, Windows | whatever you can compile on |
| Speed | ~90 ms/compile | ~30 ms/compile |
| Output | **byte-identical ROMs** | — |

From **v1.9 the only artifacts upstream publishes are wasm builds**
(`bB-1.9-wasm.tar.gz`); native is build-it-yourself. So the wasm route is now
the official cross-platform distribution, and it is the better default on any
machine without a C toolchain — notably macOS and Windows.

Verified: all five games in a test batch compiled through both toolchains
produced ROMs with identical MD5s, and the same "bytes of ROM space left".
The 60 ms difference per compile does not matter; pick either.

## Option A — wasm toolchain (portable, no build step)

```bash
export bB=$(scripts/get-bb-wasm.sh)     # fetches bB + wasmtime into the cache
scripts/bb-build.sh game.bas            # auto-detects it
BB_TOOLCHAIN=wasm scripts/bb-build.sh game.bas   # or force it
```

`get-bb-wasm.sh` caches both the bB distribution and a `wasmtime` binary under
`${XDG_CACHE_HOME:-~/.cache}/batari-basic` (override with `BB_CACHE`), so
nothing lands in a git tree and no shell profile is modified. It honours an
existing `wasmtime` on `$PATH` or `$BB_WASMTIME`.

**One gotcha if you invoke the wasm compiler yourself:** wasmtime only exposes
the directories it is handed (`--dir`), and upstream's `2600basic.sh` passes
`--dir=.`, so the compile must run *in the source directory*. From anywhere
else wasmtime cannot read the `.bas`, resolve your own `include` files, or
write the ROM. `bb-build.sh` handles this (and cleans up the intermediates
that then land beside the source).

## Option B — one-time native install

```bash
# 1. Build the bB compiler tools (needs: git, gcc/cc, make, flex)
git clone --depth 1 https://github.com/batari-Basic/batari-Basic.git batari-Basic
cd batari-Basic
make            # builds: 2600basic, preprocess, postprocess, optimize, bbfilter

# 2. Build DASM (the assembler bB calls) from upstream
cd /tmp
git clone --depth 1 https://github.com/dasm-assembler/dasm.git dasm-build
cd dasm-build
make -j4        # produces ./bin/dasm  (needs cmake? No - plain makefile; needs gcc)
cp bin/dasm /path/to/batari-Basic/dasm
```

Note: the dasm repo has no CMakeLists at root; plain `make` works. If
`make` cannot find `cmake` it isn't needed — the default target builds
`src/dasm` with the bundled Makefile.

## The 2600bas wrapper

The repo's own `2600basic.sh` runs the wasm pipeline; it falls back to
`2600basic.native.sh` on its own if wasmtime is missing *and* native binaries
are present, so a native tree is usable either way. To call the native path
unconditionally, create this wrapper as `batari-Basic/2600bas` and
`chmod +x` it:

```sh
#!/bin/sh
# Self-contained batari Basic launcher (native build).
BBDIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
export bB="$BBDIR"
for f in preprocess 2600basic postprocess bbfilter; do
  if [ ! -x "$bB/$f" ]; then
    echo "### ERROR: $bB/$f not found. Run 'make' in $bB first."
    exit 1
  fi
done
exec "$bB/2600basic.native.sh" "$@"
```

`2600basic.native.sh` (shipped by the repo, must be executable) does the real
pipeline: preprocess → 2600basic → postprocess [-O optimize] → dasm, and emits
`<file>.bas.bin` plus `.lst`/`.sym` side files. It needs the `bB` env var,
which the wrapper sets. bB also looks in `$bB/includes` for kernels and
`default.inc`, so don't relocate individual files — keep the repo layout
intact.

## Verify the install

```bash
cd /tmp && mkdir bbtest && cd bbtest
cp /path/to/batari-Basic/samples/zombie_chase.bas .
/path/to/batari-Basic/2600bas zombie_chase.bas
# expect: "Complete. (0)" and a zombie_chase.bas.bin (4096 bytes)
```

A valid standard-kernel ROM starts with bytes `78 D8` (SEI, CLD) and is a
power of 2 in size (4K default).

## Usage

```bash
batari-Basic/2600bas game.bas        # from any directory; output: game.bas.bin
batari-Basic/2600bas game.bas -O     # peephole optimizer (more ROM space)
```

- Works from any cwd — no PATH setup or `bB` export needed with the wrapper.
- `2600bas -v` prints versions.
- Optional global install: run `./install_ux.sh` inside the repo (adds
  `bB`/PATH to your shell profile). Not required.

## Running the ROM

The `.bin` runs in any Atari 2600 emulator (Stella: `stella game.bas.bin`)
or on real hardware via flash cart (Harmony). For headless validation,
compile success plus a gopher2600 HEADLESS screenshot is the strongest
check — see `running-in-an-emulator.md` for verified recipes (gopher2600,
Stella Xvfb, javatari.js, ALE). The ROM's boot bytes give a quick sanity
check.
