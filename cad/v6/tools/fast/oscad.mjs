// Fast OpenSCAD runner (WASM build with the Manifold backend).
// usage: node oscad.mjs <srcdir> <entry.scad> <out.stl> [-D name=value ...]
import { createOpenSCAD } from "openscad-wasm-prebuilt";
import fs from "node:fs";
import path from "node:path";
const [srcdir, entry, out, ...rest] = process.argv.slice(2);
const logs = [];
const os = await createOpenSCAD({ print: t => logs.push(t), printErr: t => logs.push(t) });
const inst = os.getInstance();
function mount(dir, vdir) {
  try { inst.FS.mkdir(vdir); } catch (e) {}
  for (const f of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, f.name), v = vdir + "/" + f.name;
    if (f.isDirectory()) { if (!["build", "tools", "node_modules", "renders", "__pycache__"].includes(f.name)) mount(p, v); }
    else if (/\.(scad|otf|ttf|json|txt)$/.test(f.name)) inst.FS.writeFile(v, fs.readFileSync(p));
  }
}
mount(srcdir, "/src");
// fontconfig: every .otf/.ttf under <srcdir>/fonts is made available
try { inst.FS.mkdir("/fonts"); } catch (e) {}
inst.FS.writeFile("/fonts/fonts.conf", '<?xml version="1.0"?><!DOCTYPE fontconfig SYSTEM "fonts.dtd"><fontconfig><dir>/fonts</dir><cachedir>/tmp/fc</cachedir></fontconfig>');
const fdir = path.join(srcdir, "fonts");
if (fs.existsSync(fdir)) for (const f of fs.readdirSync(fdir)) if (/\.(otf|ttf)$/.test(f)) inst.FS.writeFile("/fonts/" + f, fs.readFileSync(path.join(fdir, f)));
inst.FS.chdir("/src");
const args = ["/src/" + entry, "--backend=manifold", "--export-format=binstl", "-o", "/out.stl", ...rest];
let code;
try { code = inst.callMain(args); } catch (e) { logs.push("EXC " + e); code = 99; }
const quiet = process.env.OSCAD_QUIET;
for (const l of logs) if (!quiet || /ERROR|WARNING|ECHO|EXC|Assert/i.test(l)) console.log(l);
if (code === 0) { fs.writeFileSync(out, inst.FS.readFile("/out.stl")); }
process.exit(code);
