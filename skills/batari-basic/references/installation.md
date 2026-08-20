# Installing batari Basic

batari Basic (bB) v1.9 official releases ship as WebAssembly requiring
`wasmtime`. For agent/CLI use, build **fully native** instead — no runtime
dependencies beyond gcc/make/flex. This is the tested procedure (Linux, Ubuntu
24.04).

## One-time native install

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

The repo's own `2600basic.sh` prefers wasmtime. Create this wrapper as
`batari-Basic/2600bas` and `chmod +x` it:

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
or on real hardware via flash cart (Harmony). For headless validation, the
compile step alone (exit 0 + valid ROM size) is usually sufficient; the
ROM's boot bytes give a quick sanity check.
