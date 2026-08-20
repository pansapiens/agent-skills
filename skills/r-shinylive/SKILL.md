---
name: r-shinylive
description: Export an R Shiny app to a static, serverless site using the shinylive R package (webR/WebAssembly) and verify it actually runs in a browser before calling it done. Use this whenever the user wants to run, export, deploy, or "shinylive-ify" an R Shiny app without a Shiny server — including phrases like "make this shiny app run with shinylive", "convert this to shinylive", "static shiny app", "shiny app without a server", "host this shiny app as static files", or "set up a GitHub Actions workflow to build/deploy this shiny app". Also use it proactively if the user mentions r-shinylive, posit-dev/r-shinylive, webR, or GitHub Pages in the context of an R Shiny app. Covers the export → serve → browser-verify workflow both locally and in GitHub Actions/Pages CI, and in particular the trickiest failure mode: `shinylive::export()` silently producing an incomplete package bundle when a locally (or CI-)installed package version doesn't match what's on the wasm CRAN mirror. Does not cover deploying the exported site to a plain remote host (rsync, arbitrary web servers, file permissions) — that's ordinary static-file hosting and out of scope here.
---

# r-shinylive: export and locally verify an R Shiny app

shinylive compiles an R Shiny app into a static site that runs the actual R
interpreter in the browser via WebAssembly (webR) — no Shiny server, no
backend process. The output is just files; any static file server can host
it. This skill covers producing that output locally and proving it actually
works, which is not the same thing as export finishing without error.

## The workflow

1. **Install shinylive** (once per machine):
   ```r
   install.packages("shinylive", repos = "https://cloud.r-project.org")
   ```

2. **Install every package the app's `library()`/`require()` calls need**,
   in your normal local R library, before exporting. This isn't optional
   bookkeeping — export's dependency resolution reads the DESCRIPTION of
   whatever is already installed locally (see the gotcha below), so a
   package that isn't installed locally can't be resolved at all, and
   export fails with `there are no packages called '...'`.

3. **Export**:
   ```r
   Rscript -e 'shinylive::export(appdir = ".", destdir = "site")'
   ```
   This statically scans the app's R source for `library()`/`require()`
   calls (via `renv::dependencies()`), walks the full dependency tree, and
   downloads WebAssembly binaries for every package from the wasm CRAN
   mirror at https://repo.r-wasm.org, bundling everything — R interpreter,
   packages, app code — into `site/`.

   **Read the console output.** A line like `Package version mismatch for
   <pkg>, ensure the versions below are compatible` is not cosmetic — it
   means the export you just produced is very likely missing runtime
   dependencies. See "The version-mismatch gotcha" below before moving on.

4. **Serve locally and open in a real browser**:
   ```bash
   cd site && python3 -m http.server 8791
   ```
   Then open `http://localhost:8791/`. The first load is slow — webR itself
   plus every bundled package needs to download and initialize inside the
   browser, which routinely takes 10-30+ seconds. A blank page or spinner
   during that window is expected, not a failure. Don't conclude anything
   is broken until you've waited it out.

5. **Actually verify the app works** — don't stop at "export succeeded."
   See "Verifying it actually runs" below. This matters because the
   most common failure mode (a missing transitive dependency) produces
   *no error at export time* and only surfaces later, at runtime, the
   moment the app code that needs the missing package actually executes
   (e.g. inside a `renderPlot()` the first time a user interacts with a
   slider).

## The version-mismatch gotcha (read this before you export)

This is the thing most likely to bite you, and it's worth understanding
*why* it happens rather than just pattern-matching the fix.

`shinylive::export()` does not simply ask "what does package X depend on"
against CRAN or the wasm repo. Under the hood
(`shinylive:::resolve_dependencies()`), for each top-level package it calls
`find.package()` to locate that package **as installed in your local R
library**, builds a `local::<path>` reference to it, and asks `pkgdepends`
to walk the Depends+Imports graph starting from *that installed copy's
DESCRIPTION file* (LinkingTo is correctly excluded — compile-time-only
deps like RcppArmadillo are baked into the compiled `.so` already and
aren't needed at runtime in wasm).

The wasm binaries actually downloaded come from whatever version is
published on https://repo.r-wasm.org — which can lag behind CRAN. If your
local install is newer than the wasm-published version, and the newer
version has *fewer* dependencies than the older one (a common outcome of
package maintainers refactoring away a dependency over time), then:

- export reads your newer, leaner DESCRIPTION and concludes the
  dependency list is shorter than it really needs to be for the *old*
  version that's actually going to run in the browser,
- it downloads the old wasm binary for the top package correctly,
- but it never fetches the old version's now-dropped dependencies,
  because it never looked at the old version's DESCRIPTION,
- export finishes cleanly, no error,
- and the app breaks at runtime with something like
  `there is no package called 'polyclip'` the first time code that
  needs it runs.

Read `references/dependency-resolution.md` for the full diagnostic and fix
procedure — checking the wasm repo's real dependency list, matching the
local install to it, and a "shadow package" technique (a DESCRIPTION-only
stub, no compilation needed) for when you can't get the exact old version
built locally. Consult it as soon as you see a version-mismatch warning,
or if the app throws a "there is no package called X" error at runtime
despite export completing without complaint.

Before you even start, it's worth spot-checking that every package the
app uses is on the wasm repo at all — not everything on CRAN has a wasm
build (typically packages needing system libraries webR doesn't ship):
```bash
curl -s https://repo.r-wasm.org/src/contrib/PACKAGES | awk '/^Package: <pkgname>$/,/^$/'
```
If a package the app needs isn't listed, shinylive can't run it, full stop
— that dependency needs to be replaced, not worked around.

## Inspecting what actually got bundled

Useful for sanity-checking an export before firing up a browser:

- `ls site/shinylive/webr/packages/` — the app-specific packages that were
  downloaded. Note this does *not* include shiny's own core dependency set
  (shiny, bslib, renv, and their deps like Rcpp, cli, glue, rlang, R6,
  lifecycle) — those are resolved and bundled separately and always
  present, so their absence from this listing doesn't mean they're
  missing from the app.
- `Rscript -e 'readRDS("site/shinylive/webr/packages/metadata.rds")'` —
  resolved package metadata used for caching.
- `site/app.json` — the app's source files as bundled; useful to confirm
  the right files made it in.

## Verifying it actually runs

Export succeeding, and even the packages list looking complete, is not
proof the app works — the version-mismatch failure only shows up once the
browser actually executes the code path that needs the missing package.
Load the app in a real browser and drive it.

If you have browser automation available (Playwright, or puppeteer-core
pointed at a local Chrome install — see `references/verification.md` for
a working script), use it to:
- navigate to the served URL,
- wait genuinely long enough for webR to finish initializing (tens of
  seconds — don't give up early),
- capture browser console output, especially `pageerror` events and any R
  errors printed to the console,
- take a full-page screenshot once content has rendered, and actually
  look at it — a rendered plot or output that a working app should
  produce is much stronger evidence than "no errors appeared."

Avoid `chrome --headless --screenshot` with `--virtual-time-budget` for
this — that flag mocks timers, which can break webR's real async,
worker-thread-based startup sequence and give you a false "nothing
loaded" result. Use a scriptable tool that waits on real wall-clock time
instead.

Expect some console noise that isn't a real problem — don't chase these:
- `WebR is using 'PostMessage' communication channel, nested R REPLs are
  not available` (informational)
- `The specified value "NA" cannot be parsed, or is out of range` (from
  empty numeric inputs the app hasn't filled in yet)

If you don't have browser automation available, at minimum serve the site
and ask the user to open it and confirm it renders and responds to
interaction — don't report the task done on export success alone.

## Building and deploying via GitHub Actions

If the user wants this export automated in CI (typically to publish to
GitHub Pages), the same export command and the same version-mismatch
gotcha apply — CI installs fresh packages same as a clean local machine
would, so it's just as exposed. It also introduces its own failure modes
around *how* R packages get installed on the runner. Read
`references/github-actions.md` before writing or debugging a workflow —
it covers a real failure encountered doing exactly this: `install.packages()`
with an explicit `repos=` argument silently breaking (forces a source
build that fails on missing system libs, and doesn't fail the CI step),
the fix (`setup-r-dependencies` / pak, which installs binaries and fails
loudly), how to pin a package to the wasm-repo-matching version in CI, a
build-time sanity check pattern to catch a bad bundle automatically, the
GitHub Pages deploy actions and the repo setting they require, and a
timing gotcha when verifying the live deployed URL (it's slower than a
local file server — don't judge it broken too early).
