// Verify a locally-served shinylive app actually loads and runs.
//
// Usage:
//   npm install puppeteer-core   (run once, in a scratch dir)
//   node verify_shinylive.js <url> <output-dir> [expected-text] [chrome-path]
//
// Example:
//   node verify_shinylive.js http://localhost:8791/ /tmp/shinylive_verify "Calculating enrichment"
//
// Writes <output-dir>/screenshot.png and <output-dir>/console.log.
// Exits non-zero if a pageerror occurred or the expected text never appeared.

const puppeteer = require('puppeteer-core');
const fs = require('fs');
const path = require('path');

const url = process.argv[2];
const outDir = process.argv[3];
const expectedText = process.argv[4] || null;
const chromePath = process.argv[5] || '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';

if (!url || !outDir) {
  console.error('Usage: node verify_shinylive.js <url> <output-dir> [expected-text] [chrome-path]');
  process.exit(2);
}

fs.mkdirSync(outDir, { recursive: true });

(async () => {
  const browser = await puppeteer.launch({
    executablePath: chromePath,
    headless: 'new',
    args: ['--no-sandbox', '--disable-gpu', '--window-size=1400,1200'],
    defaultViewport: { width: 1400, height: 1200 },
  });
  const page = await browser.newPage();

  const messages = [];
  let sawPageError = false;
  // console/pageerror events bubble up to the page from all of its
  // frames, including the app iframe shinylive creates, so this single
  // pair of listeners covers both the shell and the app itself.
  page.on('console', (msg) => messages.push(`[${msg.type()}] ${msg.text()}`));
  page.on('pageerror', (err) => {
    sawPageError = true;
    messages.push(`[pageerror] ${err.message}`);
  });

  await page.goto(url, { waitUntil: 'networkidle2', timeout: 60000 });

  // shinylive renders the actual app inside a dynamically-created iframe
  // (its src is a generated app_<hash> path, not present in the static
  // index.html), so the top-level document never contains the app's
  // content — always check inside the iframe, not document.body.
  async function findAppFrame() {
    return page.frames().find((f) => f !== page.mainFrame());
  }

  // webR startup (interpreter + package downloads) is real async work —
  // give it real wall-clock time, not a mocked/virtual timer.
  let contentAppeared = true;
  if (expectedText) {
    try {
      await page.waitForFunction(() => document.querySelectorAll('iframe').length > 0, { timeout: 60000 });
      const frame = await findAppFrame();
      // Use textContent, not innerText: innerText depends on computed
      // layout/visibility, which headless Chrome doesn't always compute
      // for background tabs/windows and can spuriously read back empty
      // even once the app has genuinely rendered.
      await frame.waitForFunction(
        (text) => document.body && document.body.textContent.includes(text),
        { timeout: 60000 },
        expectedText
      );
    } catch (e) {
      contentAppeared = false;
      messages.push(`[timeout] expected text "${expectedText}" did not appear within 60s (${e.message})`);
    }
  } else {
    // No specific text given: just wait out a generous fixed window for
    // startup to settle before screenshotting.
    await new Promise((r) => setTimeout(r, 20000));
  }

  await new Promise((r) => setTimeout(r, 3000));
  await page.screenshot({ path: path.join(outDir, 'screenshot.png'), fullPage: true });
  fs.writeFileSync(path.join(outDir, 'console.log'), messages.join('\n'));

  await browser.close();

  console.log(`Screenshot: ${path.join(outDir, 'screenshot.png')}`);
  console.log(`Console log: ${path.join(outDir, 'console.log')}`);

  if (sawPageError || (expectedText && !contentAppeared)) {
    console.error('FAIL: see console.log and screenshot.png for details');
    process.exit(1);
  }
  console.log('PASS');
})();
