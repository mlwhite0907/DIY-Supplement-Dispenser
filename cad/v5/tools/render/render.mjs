// Render an STL scene to PNG with three.js in headless Chromium.
//
// usage: node render.mjs <scene.json> <out.png> [--samples N] [--quiet]
//
// The scene format is documented at the top of render.html. The local server is
// bound to 127.0.0.1 and serves ONLY files inside this render folder, so the
// scene JSON and its STL assets must live under it (tools/render/assets/...).
// Needs Playwright with Chromium: `npm i playwright && npx playwright install chromium`
// (in this repo's CI image it is preinstalled globally).
import { createRequire } from 'node:module';
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';

const require = createRequire(import.meta.url);
let chromium;
try { ({ chromium } = require('playwright')); }
catch { console.error('playwright not found: run `npm i playwright && npx playwright install chromium` in tools/render'); process.exit(2); }

const here = path.dirname(new URL(import.meta.url).pathname);
const args = process.argv.slice(2);
const flag = (n) => { const i = args.indexOf(n); if (i < 0) return null; const v = args[i + 1]; args.splice(i, 2); return v; };
const samples = flag('--samples');
const quiet = args.includes('--quiet'); if (quiet) args.splice(args.indexOf('--quiet'), 1);
const [sceneArg, outArg] = args;
if (!sceneArg || !outArg) { console.error('usage: node render.mjs <scene.json> <out.png> [--samples N]'); process.exit(2); }
const sceneRel = path.relative(here, path.resolve(sceneArg));
if (sceneRel.startsWith('..')) throw new Error('scene must live inside the render folder');
const types = { '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript', '.json': 'application/json',
                '.stl': 'application/octet-stream' };

const server = http.createServer((req, res) => {
  const rel = decodeURIComponent(new URL(req.url, 'http://localhost').pathname).replace(/^\/+/, '');
  const abs = path.resolve(here, rel);
  if (path.relative(here, abs).startsWith('..')) { res.writeHead(403); res.end(); return; }
  fs.readFile(abs, (err, data) => {
    if (err) { res.writeHead(404); res.end(); return; }
    res.writeHead(200, { 'Content-Type': types[path.extname(abs)] || 'application/octet-stream' });
    res.end(data);
  });
});
await new Promise(r => server.listen(0, '127.0.0.1', r));
const port = server.address().port;
const cfg = JSON.parse(fs.readFileSync(path.resolve(sceneArg), 'utf8'));
const t0 = Date.now();
const browser = await chromium.launch({ args: ['--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
try {
  const page = await browser.newPage({ viewport: { width: cfg.width || 1600, height: cfg.height || 1200 } });
  page.on('pageerror', e => console.error('pageerror:', e.message));
  page.on('console', m => { if (!quiet || m.type() === 'error') console.log(m.text()); });
  const q = `scene=${encodeURIComponent(sceneRel)}` + (samples ? `&samples=${encodeURIComponent(samples)}` : '');
  await page.goto(`http://127.0.0.1:${port}/render.html?${q}`);
  await page.waitForFunction(() => window.__ready === true || window.__error, null, { timeout: 3600000, polling: 500 });
  const err = await page.evaluate(() => window.__error);
  if (err) { console.error(err); process.exitCode = 1; }
  else {
    fs.mkdirSync(path.dirname(path.resolve(outArg)), { recursive: true });
    await page.locator('canvas').screenshot({ path: outArg });
    console.log(`wrote ${outArg} (${((Date.now() - t0) / 1000).toFixed(0)} s)`);
  }
} finally {
  await browser.close();
  server.close();
}
