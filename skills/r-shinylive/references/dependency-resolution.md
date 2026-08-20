# Diagnosing and fixing a version-mismatch dependency bundle

Follow this when `shinylive::export()` prints a `Package version mismatch`
warning, or when an exported app throws `there is no package called 'X'`
at runtime despite export completing cleanly.

## 1. Find out what the wasm repo actually needs

Check the real Imports/Depends for the version that's actually going to be
downloaded and run in the browser — this is ground truth, not whatever
your local library happens to have:

```bash
curl -s https://repo.r-wasm.org/src/contrib/PACKAGES | awk '/^Package: <pkgname>$/,/^$/'
```

This prints the package's `Version`, `Depends`, `Imports`, and `LinkingTo`
fields as published on the wasm mirror. Note `LinkingTo` entries — those
are compile-time-only (headers used to compile the package's C/C++ code)
and are correctly *not* needed at runtime, so don't chase them.

## 2. Compare against what's installed locally

```r
packageVersion("<pkgname>")
packageDescription("<pkgname>")$Imports
```

If the local version differs from the wasm repo's version, that's the
mismatch. The direction that matters: local newer than wasm-repo AND the
newer version's Imports list is shorter — that's the dangerous case, where
export will under-resolve dependencies.

## 3. Preferred fix: install the exact wasm-matching version locally

```r
install.packages("remotes")
remotes::install_version("<pkgname>", version = "<wasm-version>")
```

Once the locally installed DESCRIPTION genuinely matches the version being
bundled, `shinylive::export()`'s dependency walk will be correct by
construction — no further workaround needed.

This can fail if the package (or one of its dependencies) has compiled
C/C++ code and your toolchain can't build it. On macOS a common symptom is:

```
fatal error: 'vector' file not found
```

which usually means the Xcode Command Line Tools installation is missing
its C++ standard library headers (check for
`/Library/Developer/CommandLineTools/usr/include/c++/v1/vector`). Fixing
a broken CLT install (typically `xcode-select --install`, sometimes a full
reinstall) is a separate, more invasive system change — don't go down that
path as a first resort; use the shadow-package workaround below instead
unless the user specifically wants the toolchain fixed.

## 4. Fallback: shadow packages (no compilation required)

`shinylive::export()`'s dependency resolution only ever *reads* a
package's DESCRIPTION file — it never loads or executes the package. That
means you can satisfy the resolver with a fake local "install" containing
nothing but a correct DESCRIPTION.

Build one per package that needs it:

```bash
mkdir -p /tmp/shadow_lib/<pkgname>/Meta
cat > /tmp/shadow_lib/<pkgname>/DESCRIPTION << 'EOF'
Package: <pkgname>
Version: <wasm-version>
Depends: <copy from `curl .../PACKAGES` output>
Imports: <copy from `curl .../PACKAGES` output>
License: <copy from `curl .../PACKAGES` output>
NeedsCompilation: yes
EOF
```

Then prepend the shadow library to `.libPaths()` before exporting, so
`find.package()` picks up the shadow copy instead of (or in addition to)
whatever's really installed:

```r
.libPaths(c("/tmp/shadow_lib", .libPaths()))
shinylive::export(appdir = ".", destdir = "site")
```

Verify each shadow resolves the way you expect *before* re-running export:

```r
.libPaths(c("/tmp/shadow_lib", .libPaths()))
find.package("<pkgname>")             # should print the shadow path
packageDescription("<pkgname>")$Imports  # should match the wasm repo's Imports
```

### You may need a chain of shadows, not just one

If the mismatched package's real (correct) Imports pull in another package
that also needs correcting — e.g. package A's true old Imports list
includes package B, but B itself isn't installed locally at all, or is
also version-mismatched — you'll need a shadow DESCRIPTION for B too, and
so on down the chain. Work outward from the package that triggered the
original warning: fetch its real wasm-repo DESCRIPTION, shadow it, re-run
export, see what the *next* missing-package error or mismatch is, repeat.

### Don't over-shadow

Shiny's own core dependency set (`shiny`, `bslib`, `renv`, and everything
they pull in — `Rcpp`, `cli`, `glue`, `rlang`, `lifecycle`, `R6`, and
similar infrastructure packages) is resolved and bundled by shinylive
separately from your app's package list, and is essentially always
present. If one of these shows up in a resolved dependency list but is
absent from `site/shinylive/webr/packages/` after export, that's normal —
it's covered by the core bundle, not missing. Only build a shadow for a
package once you've confirmed (by checking runtime behavior, per
`verification.md`) that it's genuinely absent and needed.

## 5. Re-export and re-check

After each shadow or version fix, re-export and re-inspect
`site/shinylive/webr/packages/` (see SKILL.md's "Inspecting what actually
got bundled" section). Don't consider it resolved until you've also
verified the app runs in a browser without errors — a clean package list
is a good sign, not proof.
