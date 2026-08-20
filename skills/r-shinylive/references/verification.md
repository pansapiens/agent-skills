# Verifying an exported shinylive app actually runs

Export completing without error, and even a clean-looking package list,
does not prove the app works — the version-mismatch failure mode
(`references/dependency-resolution.md`) only surfaces once the browser
actually executes the code path that needs the missing package. Always
load the exported app in a real browser and watch what happens.

## Serving it

shinylive apps are fully static and client-side — any file server works:

```bash
cd site && python3 -m http.server 8791
```

## Headless verification with puppeteer-core

If a headless-browser tool isn't already available, `puppeteer-core`
pointed at an existing local Chrome install is lightweight (no bundled
Chromium download) and reliable for this. Install it in a scratch
directory:

```bash
mkdir -p /tmp/pptr_test && cd /tmp/pptr_test
npm init -y >/dev/null 2>&1
npm install puppeteer-core --no-audit --no-fund
```

Use `scripts/verify_shinylive.js` (bundled with this skill) as the driver,
or adapt it inline. Run it with:

```bash
node /tmp/pptr_test/verify_shinylive.js http://localhost:8791/ /tmp/shinylive_verify
```

It will:
- launch headless Chrome against your local Chrome binary,
- navigate to the served app,
- collect all console messages and page errors (this is where a
  `there is no package called 'X'` runtime error will show up),
- wait generously for the app's UI text to appear — webR startup is slow,
  routinely 10-30+ seconds on first load, so don't cut this short,
- save a full-page screenshot and a console log to the output directory.

**Actually look at the screenshot.** A rendered plot, populated output
text, or working UI controls are much stronger evidence than "no console
errors" — a blank white page with no errors can still mean something
hung.

**If you write your own check instead of using the bundled script, know
that shinylive renders the app inside a dynamically-created iframe** (its
`src` is a generated `app_<hash>/` path that only appears once the shell
page's JS creates it — it's not present in the static `index.html`). A
check like `document.body.textContent.includes(...)` against the
top-level page will wait forever and never see the app's content; you
have to check inside that iframe (`page.frames()` in puppeteer). The
bundled script already handles this.

### Why not `chrome --headless --screenshot`?

The raw CLI screenshot flag combined with `--virtual-time-budget` mocks
JS timers to fast-forward page load. webR's startup is a real
async/worker-thread sequence (spinning up a Web Worker, loading and
initializing the wasm R interpreter, fetching package binaries) — mocked
time can desync from that and produce a screenshot of a permanently-stuck
loading spinner even though the app would have loaded fine under real
wall-clock time. Prefer a scriptable tool (puppeteer, Playwright) that
waits on real time and real DOM/console events.

## What's normal noise vs. a real problem

Expect to see these in the console on a healthy app — they're not bugs:

- `WebR is using 'PostMessage' communication channel, nested R REPLs are
  not available` — informational, unrelated to your app.
- `The specified value "NA" cannot be parsed, or is out of range` —
  from Shiny numeric inputs that start out empty (`value = NA`); cosmetic
  browser warning, not an R error.
- The R startup banner (`R version ... Platform: wasm32-unknown-emscripten
  ...`) printed as `preload echo:` log lines — this is just webR booting.

Take seriously:
- Any `pageerror` event.
- Console text containing `Error in` or `there is no package called`.
- The app's expected content never appearing even after a long wait
  (suggests startup genuinely failed, not just slow).
