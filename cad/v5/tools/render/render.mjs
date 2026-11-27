// Render an STL scene to PNG with three.js in headless Chromium.
// usage: node render.mjs <scene.json> <out.png>
// The local server is bound to 127.0.0.1 and serves ONLY files inside this
// render folder (scene JSON + STL assets must be copied under ./assets).
import { createRequire } from 'node:module';
const { chromium } = createRequire(import.meta.url)('playwright');
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';

const here = path.dirname(new URL(import.meta.url).pathname);
const [,, sceneArg, outArg] = process.argv;
const sceneRel = path.relative(here, path.resolve(sceneArg));
if (sceneRel.startsWith('..')) throw new Error('scene must live inside the render folder');
const types = { '.html': 'text/html', '.js': 'text/javascript', '.json': 'application/json', '.stl': 'application/octet-stream' };

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
const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: cfg.width || 1600, height: cfg.height || 1200 } });
page.on('pageerror', e => console.error('pageerror:', e.message));
await page.goto(`http://127.0.0.1:${port}/render.html?scene=${encodeURIComponent(sceneRel)}`);
await page.waitForFunction(() => window.__ready === true || window.__error, null, { timeout: 600000 });
const err = await page.evaluate(() => window.__error);
if (err) { console.error(err); process.exitCode = 1; }
else { await page.screenshot({ path: outArg }); console.log('wrote', outArg); }
await browser.close();
server.close();
