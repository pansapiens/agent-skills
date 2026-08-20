# Building and deploying a shinylive app in GitHub Actions

The export step in CI is the same `shinylive::export()` call as local
development, which means every gotcha in `dependency-resolution.md`
applies equally — including the version-mismatch failure mode. CI doesn't
get a pass on that just because it's automated; if anything it's easier to
miss, because a CI run that goes green tells you nothing about whether the
deployed app actually works. Everything below was hit for real running
this in GitHub Actions, not theorized in advance.

## Install R packages via binaries (pak), not `install.packages(repos=...)`

Don't do this:

```yaml
- run: install.packages(c("shinylive", "eulerr"), repos = "https://cloud.r-project.org")
  shell: Rscript {0}
```

Two separate problems with it:

1. **It forces a source build.** `r-lib/actions/setup-r` configures a
   binary package repo (RSPM / Posit Package Manager) via the
   `use-public-rspm: true` option, but passing an explicit `repos =`
   argument to `install.packages()` overrides that entirely and falls
   back to CRAN source tarballs. On a stock `ubuntu-latest` runner this
   fails for any package needing a system library that isn't
   preinstalled — `curl` needs `libcurl4-openssl-dev`, `ps`/`httpuv`-chain
   packages need `libuv1-dev`, etc. — with errors like
   `fatal error: curl/curl.h: No such file or directory`.
2. **It fails silently.** `install.packages()` given a vector of package
   names doesn't stop on one failure — it warns and moves on to the next
   package. The step exits 0. The *next* step (`shinylive::export()`)
   is what actually errors, with something unhelpful like
   `there is no package called 'shinylive'`, several steps removed from
   the real cause. If you see that error in an export step, the actual
   problem is almost always back in the install step's log.

Use `r-lib/actions/setup-r-dependencies` instead — it installs via `pak`,
which pulls prebuilt binaries from RSPM (no compiler toolchain needed) and
genuinely fails the step if a package can't be installed:

```yaml
- uses: r-lib/actions/setup-r@v2
  with:
    r-version: "release"
    use-public-rspm: true

- uses: r-lib/actions/setup-r-dependencies@v2
  with:
    packages: |
      any::shinylive
      any::eulerr
      any::scales
```

## The version-mismatch gotcha hits CI too — pin the exact version

CI installs whatever's currently newest on CRAN, same as a fresh local
`install.packages()` would. If that's ahead of what's published on the
wasm repo (https://repo.r-wasm.org/src/contrib/PACKAGES) and the newer
CRAN version has fewer declared dependencies, you get the exact same
silent-incomplete-bundle failure described in `dependency-resolution.md`
— export succeeds, CI goes green, and the deployed app breaks in the
browser the first time it needs the missing package.

Fix it the same way as locally, but simpler: `pak` package specs support
version pins directly (`pkgname@version`), and RSPM keeps binaries for
past versions too, so pinning doesn't force a source build:

```yaml
    packages: |
      any::shinylive
      eulerr@7.1.0
      any::scales
```

Check `https://repo.r-wasm.org/src/contrib/PACKAGES` for the current wasm
version before setting the pin, and leave a comment explaining *why* it's
pinned — otherwise a future dependency bump (e.g. Dependabot, or someone
tidying the workflow) will "fix" the pin back to `any::eulerr` and
silently reintroduce the bug. Comment example:

```yaml
    # eulerr is pinned to 7.1.0 to match the version currently published
    # on the shinylive/webR wasm package repo. If this starts failing,
    # re-check the wasm repo's current eulerr version and update the pin
    # to match — don't just remove it.
```

## Add a build-time sanity check for the packages that actually matter

Because this failure mode is silent at export time, it's worth spending
one cheap CI step to catch it automatically instead of relying on someone
remembering to check manually. After export, assert that the packages you
know the app's compiled-dependency chain actually needs (from checking
the wasm repo's real `Imports`, per `dependency-resolution.md`) are
present in the bundle:

```yaml
- name: Sanity-check bundled packages
  run: |
    set -euo pipefail
    for pkg in eulerr polyclip GenSA polylabelr scales; do
      if [ ! -d "site/shinylive/webr/packages/$pkg" ]; then
        echo "::error::Expected package '$pkg' missing from site/shinylive/webr/packages/"
        exit 1
      fi
    done
```

This won't catch every possible dependency issue, but it directly guards
the one failure mode that's both silent and has actually happened.

## Deploying the export to GitHub Pages

The exported `site/` directory is static, so the official Pages actions
are enough — no custom server, no `gh-pages` branch push needed. Repo
setting required first: **Settings → Pages → Source → "GitHub Actions"**
(not "Deploy from a branch") — the workflow will not work without this
being set, and there's no error if you forget, the Pages deploy step just
has nothing to publish to.

```yaml
permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: pages
  cancel-in-progress: true

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      # ... checkout, setup-r, setup-r-dependencies, export, sanity-check ...
      - uses: actions/configure-pages@v5
      - uses: actions/upload-pages-artifact@v3
        with:
          path: site

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - id: deployment
        uses: actions/deploy-pages@v4
```

## Verifying the actual deployed site, not just a green run

A passing workflow proves export produced *a* bundle, not that the live
site works — re-run the same browser verification from
`verification.md` against the real Pages URL once deployed, don't just
trust the checkmark.

One timing gotcha specific to this: a fixed wait tuned against a local
`python3 -m http.server` (fast, same machine, no real network) can be too
short against the actual GitHub Pages CDN. In practice, hitting the live
URL and taking a screenshot after ~20s showed the static UI shell
rendered but every reactive output (plots, computed text, p-values) still
blank — not because anything was broken, just because R's server-side
evaluation genuinely hadn't finished yet over the real network. Waiting
longer (60s) showed everything rendered correctly. If you verify a live
deployment and see a shell with no computed output, don't conclude it's
broken until you've given it more time than you did locally.
