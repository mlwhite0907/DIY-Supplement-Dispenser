"""Shared plumbing for the Dose Bar v5 tools: build.py, fitcheck.py, render_all.py.

Nothing in here knows part geometry. This module:
  * reads the entry file (dosebar.scad): the PARTS registry, the COLORS table
    and the posed()/printed() dispatch tables,
  * reads jar presets (presets/<name>.scad) as NAME = value; lines,
  * runs OpenSCAD with -D defines as an argument list (no shell),
  * caches exports by a fingerprint of the sources they depend on,
  * evaluates OpenSCAD expressions (V_MAX, PUCK_R, ...) through an echo export,
  * measures STLs with trimesh (watertight, volume, bbox, grams).

Python 3.8+, numpy, trimesh. fitcheck.py also needs manifold3d.
OpenSCAD is found on PATH, in $OPENSCAD, or in the default macOS/Windows install.
"""
from __future__ import annotations

import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import threading
import time
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

TOOLS = Path(__file__).resolve().parent
V5 = TOOLS.parent
ENTRY = V5 / "dosebar.scad"
PARAMS = V5 / "params.scad"
LIB = V5 / "lib"
PARTS_DIR = V5 / "parts"
PRESETS_DIR = V5 / "presets"
BUILD = V5 / "build"
RENDER_DIR = TOOLS / "render"

BED_MM = 250.0                              # P2S is 256^3; keep 3 mm per side spare
DENSITY = {"PLA": 1.24, "TPU": 1.21}        # g/cm3
SHELL_MM = 1.2                              # perimeters + skins as an equivalent solid shell
INFILL = 0.15                               # sparse infill fraction inside the shell
BASE_STATE_VARS = ("STATE_PULL", "DIAL_ML", "CHUCK_CLOSE")
OPTIONAL_STATE_VARS = ("DRAWER_OUT",)        # v5.1: dose drawer slid out (0/1), if params defines it


def _detect_state_vars():
    try:
        t = strip_scad_comments(PARAMS.read_text())
    except OSError:
        return BASE_STATE_VARS
    extra = tuple(v for v in OPTIONAL_STATE_VARS if re.search(r"^\s*" + v + r"\s*=", t, re.M))
    return BASE_STATE_VARS + extra


STATE_VARS = None   # set below, once the helpers exist
TOOL_VERSION = "v5-tools-2"                 # bump to invalidate every cached export

_print_lock = threading.Lock()


def say(*a, **kw):
    """Thread-safe print that flushes (tools run long OpenSCAD jobs in parallel)."""
    with _print_lock:
        print(*a, **kw, flush=True)


# --------------------------------------------------------------------------- OpenSCAD
def find_openscad() -> str:
    env = os.environ.get("OPENSCAD")
    if env:
        return env
    for cand in (shutil.which("openscad"),
                 "/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD",
                 r"C:\Program Files\OpenSCAD\openscad.exe"):
        if cand and os.path.exists(cand):
            return cand
    raise SystemExit("OpenSCAD not found. Install it or set OPENSCAD=/path/to/openscad")


_OPENSCAD_VERSION = None


def openscad_version() -> str:
    global _OPENSCAD_VERSION
    if _OPENSCAD_VERSION is None:
        try:
            p = subprocess.run([find_openscad(), "--version"], capture_output=True, text=True, timeout=60)
            _OPENSCAD_VERSION = ((p.stdout or "") + (p.stderr or "")).strip().splitlines()[-1]
        except Exception as e:  # noqa: BLE001
            _OPENSCAD_VERSION = f"unknown ({e})"
    return _OPENSCAD_VERSION


class ScadResult(dict):
    """status: ok | empty (stub or nothing to export) | error | timeout."""
    __getattr__ = dict.get


def run_openscad(out, defs, src=ENTRY, timeout=900) -> ScadResult:
    """Export `src` to `out` with -D defines (list of 'NAME=value'). Never uses a shell.

    The file is written to a temp name and renamed on success, so a crashed or
    empty export never leaves a stale STL behind.
    """
    out = Path(out)
    out.parent.mkdir(parents=True, exist_ok=True)
    tmp = out.with_name(f".{out.stem}.{os.getpid()}-{threading.get_ident()}.tmp{out.suffix}")
    cmd = [find_openscad(), "-o", str(tmp)]
    for d in defs:
        cmd += ["-D", d]
    cmd.append(str(src))
    t0 = time.monotonic()
    try:
        p = subprocess.run(cmd, cwd=str(V5), capture_output=True, text=True, timeout=timeout)
        log, rc = (p.stdout or "") + (p.stderr or ""), p.returncode
    except subprocess.TimeoutExpired as e:
        tmp.unlink(missing_ok=True)
        return ScadResult(status="timeout", path=None, seconds=time.monotonic() - t0,
                          log=str(e), errors=[f"timeout after {timeout}s"], warnings=[], echoes=[])
    dt = time.monotonic() - t0
    lines = log.splitlines()
    errors = [ln for ln in lines if ln.startswith("ERROR")]
    warnings = [ln for ln in lines if ln.startswith(("WARNING", "DEPRECATED"))]
    echoes = [ln for ln in lines if ln.startswith("ECHO")]
    ok_file = tmp.exists() and tmp.stat().st_size > 0
    if rc == 0 and ok_file and not errors:
        os.replace(tmp, out)
        status = "ok"
    else:
        tmp.unlink(missing_ok=True)
        status = "empty" if "Current top level object is empty" in log and not errors else "error"
        if status == "error" and not errors:
            errors = [ln for ln in lines[-6:] if ln.strip()] or [f"openscad exit {rc}"]
    return ScadResult(status=status, path=str(out) if status == "ok" else None, seconds=dt,
                      log=log, errors=errors, warnings=warnings, echoes=echoes, cmd=cmd)


# --------------------------------------------------------------------------- SCAD text
def strip_scad_comments(text: str) -> str:
    """Remove // and /* */ comments; string literals are kept intact; newlines are kept."""
    out, i, n, q = [], 0, len(text), False
    while i < n:
        c = text[i]
        if q:
            out.append(c)
            if c == "\\" and i + 1 < n:
                out.append(text[i + 1])
                i += 2
                continue
            if c == '"':
                q = False
            i += 1
            continue
        if c == '"':
            q = True
            out.append(c)
            i += 1
        elif text.startswith("//", i):
            j = text.find("\n", i)
            i = n if j < 0 else j
        elif text.startswith("/*", i):
            j = text.find("*/", i + 2)
            seg = text[i:(n if j < 0 else j + 2)]
            out.append("\n" * seg.count("\n"))
            i = n if j < 0 else j + 2
        else:
            out.append(c)
            i += 1
    return "".join(out)


STATE_VARS = _detect_state_vars()


def split_statements(text: str):
    """Split SCAD source on ';' that are outside strings and brackets."""
    parts, buf, depth, q, i = [], [], 0, False, 0
    while i < len(text):
        c = text[i]
        buf.append(c)
        if q:
            if c == "\\" and i + 1 < len(text):
                buf.append(text[i + 1])
                i += 1
            elif c == '"':
                q = False
        elif c == '"':
            q = True
        elif c in "([{":
            depth += 1
        elif c in ")]}":
            depth -= 1
        elif c == ";" and depth <= 0:
            parts.append("".join(buf[:-1]).strip())
            buf = []
        i += 1
    if "".join(buf).strip():
        parts.append("".join(buf).strip())
    return parts


def _match(text: str, i: int) -> int:
    """Index of the bracket that closes text[i] (one of ([{), skipping strings."""
    pairs = {"(": ")", "[": "]", "{": "}"}
    stack, q, j = [], False, i
    while j < len(text):
        c = text[j]
        if q:
            if c == "\\":
                j += 1
            elif c == '"':
                q = False
        elif c == '"':
            q = True
        elif c in pairs:
            stack.append(pairs[c])
        elif stack and c == stack[-1]:
            stack.pop()
            if not stack:
                return j
        j += 1
    raise ValueError("unbalanced brackets in SCAD source")


def scad_str(s: str) -> str:
    """Python str -> OpenSCAD string literal."""
    return '"' + str(s).replace("\\", "\\\\").replace('"', '\\"') + '"'


def scad_num(v) -> str:
    return f"{float(v):.6g}" if not float(v).is_integer() else str(int(float(v)))


# --------------------------------------------------------------------------- presets
def list_presets(include_private=False):
    names = sorted(p.stem for p in PRESETS_DIR.glob("*.scad"))
    return [n for n in names if include_private or not n.startswith("_")]


def preset_path(name) -> Path:
    p = Path(name)
    if p.suffix == ".scad" and p.exists():
        return p.resolve()
    p = PRESETS_DIR / f"{name}.scad"
    if not p.exists():
        raise SystemExit(f"preset not found: {p}\n  available: {', '.join(list_presets(True))}")
    return p


def preset_label(name) -> str:
    return preset_path(name).stem


_ASSIGN = re.compile(r"^([A-Za-z_]\w*)\s*=\s*(.+)$", re.S)


def read_preset(name) -> dict:
    """{NAME: raw SCAD value} for every top-level NAME = value; in the preset (order kept)."""
    vals = {}
    for stmt in split_statements(strip_scad_comments(preset_path(name).read_text())):
        m = _ASSIGN.match(stmt.strip())
        if m:
            vals[m.group(1)] = " ".join(m.group(2).split())
    return vals


def defs_from(vals: dict) -> list:
    """{NAME: raw value} -> ['NAME=value', ...] (string values keep their quotes)."""
    return [f"{k}={v}" for k, v in vals.items()]


# --------------------------------------------------------------------------- entry file
def entry_text() -> str:
    return strip_scad_comments(ENTRY.read_text())


def parts_registry(text=None) -> list:
    """PARTS = [[name, material, qty, color_role], ...] from dosebar.scad."""
    t = text if text is not None else entry_text()
    m = re.search(r"\bPARTS\s*=\s*\[", t)
    if not m:
        raise SystemExit("PARTS registry not found in dosebar.scad")
    i = m.end() - 1
    body = t[i + 1:_match(t, i)]
    rows = re.findall(r'\[\s*"([^"]*)"\s*,\s*"([^"]*)"\s*,\s*([-+0-9.eE]+)\s*,\s*"([^"]*)"\s*\]', body)
    out = []
    for name, mat, qty, role in rows:
        q = float(qty)
        out.append({"name": name, "material": mat, "qty": int(q) if q.is_integer() else q, "color": role})
    return out


def color_table(text=None) -> dict:
    t = text if text is not None else entry_text()
    m = re.search(r"\bCOLORS\s*=\s*\[", t)
    if not m:
        return {}
    i = m.end() - 1
    return dict(re.findall(r'\[\s*"([^"]+)"\s*,\s*"([^"]+)"\s*\]', t[i + 1:_match(t, i)]))


def dispatch_names(module: str, text=None) -> list:
    """Part names handled by `module posed(name)` / `module printed(name)` (in order)."""
    t = text if text is not None else entry_text()
    m = re.search(r"\bmodule\s+" + re.escape(module) + r"\s*\(\s*name\s*\)\s*\{", t)
    if not m:
        return []
    body = t[m.end():_match(t, m.end() - 1)]
    seen = []
    for n in re.findall(r'name\s*==\s*"([^"]+)"', body):
        if n not in seen:
            seen.append(n)
    return seen


def default_name(text=None) -> str:
    m = re.search(r'^\s*NAME\s*=\s*"([^"]*)"\s*;', text if text is not None else entry_text(), re.M)
    return m.group(1) if m else "NAME"


# --------------------------------------------------------------------------- fingerprints
def _sha(*chunks) -> str:
    h = hashlib.sha1()
    for c in chunks:
        h.update(c if isinstance(c, bytes) else str(c).encode())
        h.update(b"\0")
    return h.hexdigest()


def file_sha(path) -> str:
    """sha1 of a file; "missing" if it vanished (part files get rewritten while tools run)."""
    h = hashlib.sha1()
    try:
        with open(path, "rb") as f:
            for chunk in iter(lambda: f.read(1 << 20), b""):
                h.update(chunk)
    except FileNotFoundError:
        return "missing"
    return h.hexdigest()


def read_text_safe(path) -> str:
    try:
        return Path(path).read_text()
    except (FileNotFoundError, UnicodeDecodeError):
        return ""


_IDENT = re.compile(r"[A-Za-z_]\w*")
_STR = re.compile(r'"(?:\\.|[^"\\])*"')


def top_level_statements(text: str):
    """Top-level statements of comment/string-stripped SCAD (module bodies stay whole)."""
    out, buf, depth = [], [], 0
    for c in text:
        buf.append(c)
        if c in "([{":
            depth += 1
        elif c in ")]}":
            depth -= 1
            if c == "}" and depth == 0:
                out.append("".join(buf).strip())
                buf = []
        elif c == ";" and depth == 0:
            out.append("".join(buf[:-1]).strip())
            buf = []
    if "".join(buf).strip():
        out.append("".join(buf).strip())
    return out


class SourceIndex:
    """Which part files a module depends on (OpenSCAD's include makes one flat namespace).

    Every part file is scanned for the modules/functions/top-level constants it
    defines and the identifiers it uses. The fingerprint of an export is the hash
    of the global sources (entry, params, lib, preset values) plus the transitive
    closure of part files reachable from the module being exported. Editing
    parts/jaw.scad therefore never invalidates a cached slide export.
    """

    def __init__(self):
        self.files = sorted(PARTS_DIR.glob("*.scad"))
        self.defs, self.uses, self.incl, self.modules, self.text = {}, {}, {}, set(), {}
        for f in self.files:
            raw = read_text_safe(f)
            t = strip_scad_comments(raw)
            t_nostr = re.sub(r'"(?:\\.|[^"\\])*"', '""', t)
            self.text[f] = t_nostr
            # top-level definitions only (a let() or a local in a module body is not a global)
            mods, names = set(), set()
            for stmt in top_level_statements(t_nostr):
                m = re.match(r"^(module|function)\s+([A-Za-z_]\w*)\s*\(", stmt)
                if m:
                    (mods if m.group(1) == "module" else names).add(m.group(2))
                    continue
                m = re.match(r"^([A-Za-z_]\w*)\s*=", stmt)
                if m:
                    names.add(m.group(1))
            self.modules |= mods
            names |= mods
            for n in names:
                self.defs.setdefault(n, f)
            self.uses[f] = set(_IDENT.findall(t_nostr))
            inc = set()
            for p in re.findall(r"\b(?:include|use)\s*<([^>]+)>", t):
                q = (f.parent / p).resolve()
                if q.exists() and q != PARAMS.resolve() and LIB.resolve() not in q.parents:
                    inc.add(q)
            self.incl[f] = inc
        self.global_files = [ENTRY, PARAMS] + sorted(LIB.glob("*.scad"))
        self._global = _sha(TOOL_VERSION, openscad_version(),
                            *[f"{p.name}:{file_sha(p)}" for p in self.global_files])

    def closure(self, module_names) -> list:
        start = {self.defs[n] for n in module_names if n in self.defs}
        if not start:                 # unknown module: depend on every part file (safe)
            return list(self.files)
        seen, todo = set(), list(start)
        while todo:
            f = todo.pop()
            if f in seen:
                continue
            seen.add(f)
            for ident in self.uses.get(f, ()):
                g = self.defs.get(ident)
                if g is not None and g not in seen:
                    todo.append(g)
            for g in self.incl.get(f, ()):
                if g not in seen:
                    todo.append(g)
        return sorted(seen)

    def _taint(self) -> dict:
        """{identifier: set of state variables it depends on}, over params, lib, entry and parts."""
        if getattr(self, "_taint_cache", None) is not None:
            return self._taint_cache
        graph = {}
        for f in [PARAMS, *sorted(LIB.glob("*.scad")), ENTRY, *self.files]:
            t = _STR.sub('""', strip_scad_comments(read_text_safe(f)))
            for stmt in top_level_statements(t):
                m = re.match(r"^([A-Za-z_]\w*)\s*=\s*(.*)$", stmt, re.S)
                if m:
                    graph.setdefault(m.group(1), set()).update(_IDENT.findall(m.group(2)))
                    continue
                m = re.match(r"^function\s+([A-Za-z_]\w*)\s*\(([^)]*)\)\s*=\s*(.*)$", stmt, re.S)
                if m:
                    args = set(_IDENT.findall(m.group(2)))
                    graph.setdefault(m.group(1), set()).update(set(_IDENT.findall(m.group(3))) - args)
        taint = {v: {v} for v in STATE_VARS}
        changed = True
        while changed:
            changed = False
            for name, ids in graph.items():
                t = set()
                for i in ids:
                    t |= taint.get(i, set())
                if t - taint.get(name, set()):
                    taint[name] = taint.get(name, set()) | t
                    changed = True
        self._taint_cache = taint
        return taint

    def state_deps(self, module_names) -> list:
        """State variables (STATE_PULL, DIAL_ML, CHUCK_CLOSE) a module can depend on.

        Static and conservative: a part depends on a state variable if any source
        file it can reach names an identifier derived from that variable (SLIDE_Y0,
        CH_L, DIAL_ANGLE, R_PIN, RING_PHI, ...). Never misses a dependency; at worst
        a part is exported once more than needed.
        """
        taint = self._taint()
        ids = set()
        for f in self.closure(module_names):
            ids |= self.uses.get(f, set())
        return [v for v in STATE_VARS if any(v in taint.get(i, ()) for i in ids)]

    def calls_in(self, module) -> list:
        """Modules (defined in part files or the entry) called inside `module`'s body."""
        known = self.modules | {"head_assembly", "jar_ghost", "posed", "printed"}
        for f, t in self.text.items():
            m = re.search(r"\bmodule\s+" + re.escape(module) + r"\s*\([^)]*\)\s*\{", t)
            if m:
                body = t[m.end():_match(t, m.end() - 1)]
                return sorted({c for c in re.findall(r"\b([A-Za-z_]\w*)\s*\(", body) if c in known and c != module})
        return []

    def fingerprint(self, module_names, defs, extra="") -> str:
        files = self.closure(module_names)
        return _sha(self._global, extra, *sorted(defs),
                    *[f"{p.name}:{file_sha(p)}" for p in files])


# --------------------------------------------------------------------------- evaluation
_ECHO_RE = re.compile(r'^ECHO: (__v\d+) = (.*)$')


def _parse_scad_value(s: str):
    s = s.strip()
    try:
        return json.loads(re.sub(r"\bundef\b", "null", s))
    except Exception:  # noqa: BLE001
        try:
            return float(s)
        except ValueError:
            return s


def eval_scad(exprs, defs, scratch=None) -> dict:
    """Evaluate OpenSCAD expressions in the context of dosebar.scad + defines.

    eval_scad(["V_MAX", "PUCK_R"], defs) -> {"V_MAX": 40, "PUCK_R": 78.75}
    """
    exprs = list(exprs)
    scratch = Path(scratch or BUILD / ".scad")
    scratch.mkdir(parents=True, exist_ok=True)
    body = f"include <{ENTRY.as_posix()}>\n" + "".join(
        f"echo(__v{i} = {e});\n" for i, e in enumerate(exprs))
    src = scratch / f"eval_{_sha(body)[:12]}.scad"
    if not src.exists():
        src.write_text(body)
    out = scratch / f"eval_{os.getpid()}_{threading.get_ident()}.echo"
    res = run_openscad(out, list(defs) + ['PART="__none__"'], src=src, timeout=300)
    text = Path(out).read_text() if res.status == "ok" else res.log
    Path(out).unlink(missing_ok=True)
    vals = {}
    for ln in text.splitlines():
        m = _ECHO_RE.match(ln.strip())
        if m:
            vals[exprs[int(m.group(1)[3:])]] = _parse_scad_value(m.group(2))
    missing = [e for e in exprs if e not in vals]
    if missing:
        raise RuntimeError(f"could not evaluate {missing}:\n" + "\n".join(res.errors or res.log.splitlines()[-8:]))
    return vals


# --------------------------------------------------------------------------- STL metrics
def load_mesh(path):
    import trimesh
    m = trimesh.load(str(path), force="mesh")
    return m


def count_bodies(faces, n_vertices) -> int:
    """Number of vertex-connected components (no scipy/networkx needed)."""
    import numpy as np
    faces = np.asarray(faces)
    if len(faces) == 0:
        return 0
    lab = np.arange(n_vertices)
    e = np.concatenate([faces[:, [0, 1]], faces[:, [1, 2]]])
    while True:
        a, b = lab[e[:, 0]], lab[e[:, 1]]
        lo = np.minimum(a, b)
        new = lab.copy()
        np.minimum.at(new, a, lo)
        np.minimum.at(new, b, lo)
        while True:                        # pointer jumping
            nxt = new[new]
            if np.array_equal(nxt, new):
                break
            new = nxt
        if np.array_equal(new, lab):
            break
        lab = new
    return int(len(np.unique(lab[np.unique(faces)])))


def stl_metrics(path, material="PLA") -> dict:
    """Watertight, volume, area, bbox, bodies and estimated grams of an STL."""
    m = load_mesh(path)
    ext = (m.bounds[1] - m.bounds[0]).tolist() if len(m.vertices) else [0, 0, 0]
    wt = bool(m.is_watertight)
    vol = float(abs(m.volume)) if wt else float(m.volume)
    area = float(m.area)
    bodies = count_bodies(m.faces, len(m.vertices))
    rho = DENSITY.get(material.upper(), DENSITY["PLA"])
    v = max(vol, 0.0)
    shell = min(v, area * SHELL_MM)
    grams = rho * (shell + INFILL * (v - shell)) / 1000.0
    fits = all(e <= BED_MM + 1e-6 for e in ext)
    return {
        "watertight": wt, "volume_mm3": round(vol, 2), "area_mm2": round(area, 1),
        "bbox_mm": [round(e, 2) for e in ext],
        "bounds_mm": [[round(x, 3) for x in m.bounds[0].tolist()], [round(x, 3) for x in m.bounds[1].tolist()]]
        if len(m.vertices) else None,
        "triangles": int(len(m.faces)), "bodies": bodies,
        "fits_bed": fits, "grams": round(grams, 2),
    }


def stl_to_binary(src, dst):
    """Re-save an (ASCII) OpenSCAD STL as compact binary STL for the web renderer."""
    m = load_mesh(src)
    Path(dst).parent.mkdir(parents=True, exist_ok=True)
    tmp = Path(dst).with_suffix(".tmp")
    m.export(str(tmp), file_type="stl")
    os.replace(tmp, dst)
    return dst


def geom_sha(path) -> str:
    """Hash of an STL's geometry that ignores facet order.

    OpenSCAD/CGAL writes the same solid with its facets in a different order from
    run to run, so a file hash cannot tell "same part" from "moved part". This
    hashes the sorted set of vertices (rounded to 0.1 um), the facet count and the
    volume, which is stable for identical geometry and changes when a part moves.
    """
    import numpy as np
    m = load_mesh(path)
    v = np.unique(np.round(np.asarray(m.vertices, dtype=np.float64), 4), axis=0)
    return _sha(v.tobytes(), len(m.faces), f"{float(m.volume):.3f}")


def write_json_atomic(path, obj, indent=1):
    path = Path(path)
    tmp = path.with_name(f".{path.name}.{os.getpid()}-{threading.get_ident()}.tmp")
    tmp.write_text(json.dumps(obj, indent=indent, default=str))
    os.replace(tmp, path)


# --------------------------------------------------------------------------- posed export cache
def state_key(state: dict) -> str:
    return ",".join(f"{k.split('_')[-1].lower()}={float(state.get(k, 0)):g}" for k in STATE_VARS)


class PosedCache:
    """Posed exports (head coordinates) of one preset, cached under build/fit/<preset>/.

    Cache key: (part, canonical state, preset). A part is only re-exported when
    a source it depends on changes. A part that does not depend on a state
    variable (static analysis, SourceIndex.state_deps) is exported once for all
    values of it.
    """

    BASE = {"STATE_PULL": 0, "DIAL_ML": 0, "CHUCK_CLOSE": 0, "DRAWER_OUT": 0}

    def __init__(self, preset="std", name=None, jobs=3, timeout=900, root=None, force=False, quiet=False):
        self.preset = preset_label(preset)
        self.vals = read_preset(preset)
        self.name = name if name is not None else default_name()
        self.base_defs = defs_from(self.vals) + [f"NAME={scad_str(self.name)}"]
        self.dir = Path(root or BUILD / "fit") / self.preset
        self.dir.mkdir(parents=True, exist_ok=True)
        self.jobs, self.timeout, self.force, self.quiet = jobs, timeout, force, quiet
        self.src = SourceIndex()
        self.text = entry_text()
        self.posed_names = dispatch_names("posed", self.text)
        self.registry = parts_registry(self.text)
        # head parts = PARTS registry entries that posed() can place (bay/leg/foot are bar parts;
        # helper names such as jaw0 or params_json in posed() are not separate parts)
        self.head_parts = [r["name"] for r in self.registry if r["name"] in self.posed_names]
        self.params = eval_scad(["V_MAX", "CLASS_NAME", "JAR_NAME"], self.base_defs, self.dir / "_scad")

    # -- generic cached export ------------------------------------------------
    def _export(self, label, part_value, defs, modules, src=ENTRY, wrapper=None):
        """Export one STL if its fingerprint changed. Returns dict(status, path, sha, seconds)."""
        out = self.dir / f"{label}.stl"
        side = self.dir / f"{label}.json"
        fp = self.src.fingerprint(modules, defs + [f"PART={part_value}"], extra=wrapper or "")
        if not self.force and out.exists() and side.exists():
            try:
                meta = json.loads(side.read_text())
                if meta.get("fingerprint") == fp and meta.get("status") == "ok":
                    return {**meta, "path": str(out), "cached": True}
            except Exception:  # noqa: BLE001
                pass
        if not self.force and side.exists() and not out.exists():
            try:
                meta = json.loads(side.read_text())
                if meta.get("fingerprint") == fp and meta.get("status") == "empty":
                    return {**meta, "path": None, "cached": True}
            except Exception:  # noqa: BLE001
                pass
        res = run_openscad(out, defs + [f"PART={part_value}"], src=src, timeout=self.timeout)
        meta = {"fingerprint": fp, "status": res.status, "seconds": round(res.seconds, 2),
                "errors": res.errors[:8], "warnings": res.warnings[:8]}
        if res.status == "ok":
            meta["sha"] = geom_sha(out)
        else:
            out.unlink(missing_ok=True)
        write_json_atomic(side, meta)
        if not self.quiet and res.status != "empty":
            say(f"  exported {self.preset}/{label}: {res.status} ({res.seconds:.0f}s)"
                + (f"  {'; '.join(res.errors[:2])[:200]}" if res.errors else ""))
        return {**meta, "path": str(out) if res.status == "ok" else None, "cached": False}

    def _state_defs(self, state):
        return [f"{k}={scad_num(state[k])}" for k in STATE_VARS]

    def export_state(self, part, state):
        st = {k: state.get(k, self.BASE[k]) for k in STATE_VARS}
        label = f"{part}@{state_key(st)}"
        return self._export(label, scad_str(f"posed:{part}"), self.base_defs + self._state_defs(st), [part])

    # -- state dependence -------------------------------------------------------
    def deps(self, parts) -> dict:
        """{part: [state variables it moves with]} from static analysis of the sources."""
        return {p: self.src.state_deps([p]) for p in parts}

    def canonical(self, part, state, deps):
        st = dict(self.BASE)
        for v in deps or []:
            st[v] = state.get(v, self.BASE[v])
        return st

    def export_states(self, part_states, deps=None):
        """[(part, state)] -> {(part, state_key): result}. Exports unique canonical states in parallel."""
        parts = sorted({p for p, _ in part_states})
        deps = deps or self.deps(parts)
        uniq, mapping = {}, {}
        for p, st in part_states:
            c = self.canonical(p, st, deps.get(p))
            uniq[(p, state_key(c))] = (p, c)
            mapping[(p, state_key(st))] = (p, state_key(c))
        with ThreadPoolExecutor(max_workers=self.jobs) as ex:
            done = dict(zip(uniq.keys(), ex.map(lambda pc: self.export_state(*pc), uniq.values())))
        return {k: done[v] for k, v in mapping.items()}

    # -- jar ghost, powder fill, whole bar --------------------------------------
    def export_wrapper(self, label, body, extra_defs=()):
        """Export a generated wrapper: include dosebar.scad, then `body` at top level."""
        sd = self.dir / "_scad"
        sd.mkdir(parents=True, exist_ok=True)
        text = f"include <{ENTRY.as_posix()}>\n{body}\n"
        src = sd / f"{label}.scad"
        if not src.exists() or src.read_text() != text:
            src.write_text(text)
        return self._export(label, scad_str("__none__"), self.base_defs + list(extra_defs), ["__entry__"],
                            src=src, wrapper=text)

    def export_jar(self):
        return self.export_wrapper("jar", "jar_ghost();")

    def export_powder(self, fill=0.6):
        """Opaque powder inside the jar ghost: its inner cavity, filled `fill` of JAR_H from the rim.

        Mirrors the inner profile of jar_ghost() in dosebar.scad, inset 0.4 mm.
        """
        g = 0.4
        body = f"""
_pf = {float(fill):.4f};
_ph = max(2, _pf*(JAR_H - 6));
translate([0, 0, Z_RIM + 0.3]) intersection() {{
    rotate_extrude($fn=96) polygon([
        [0, 0], [MOUTH_ID/2 - {g}, 0], [MOUTH_ID/2 - {g}, NECK_H],
        [NECK_OD/2 - 3 - {g}, NECK_H + 2], [BODY_OD/2 - 3 - {g}, NECK_H + 19],
        [BODY_OD/2 - 3 - {g}, JAR_H - 14], [BODY_OD/2 - 11 - {g}, JAR_H - 6 - {g}], [0, JAR_H - 6 - {g}]]);
    translate([0, 0, -1]) cylinder(r=BODY_OD, h=_ph + 1, $fn=24);
}}
"""
        return self.export_wrapper(f"powder_{int(round(fill * 100))}", body)

    def export_row(self, n=2):
        """row_assembly(n) WITHOUT its heads (head_assembly() is overridden to nothing):
        whatever the row adds between heads, i.e. the joiners."""
        body = f"module head_assembly() {{}}\nrow_assembly({int(n)});"
        return self.export_wrapper(f"row{int(n)}_extras", body, [f"ROW_N={int(n)}"])


def fmt_state(st) -> str:
    s = f"pull {float(st['STATE_PULL']):g}, dial {float(st['DIAL_ML']):g} mL, chuck {float(st['CHUCK_CLOSE']):g}"
    if "DRAWER_OUT" in STATE_VARS and float(st.get("DRAWER_OUT", 0)):
        s += ", drawer out"
    return s


def require(mod):
    try:
        return __import__(mod)
    except ImportError:
        raise SystemExit(f"missing Python package '{mod}': pip install {mod}")


if __name__ == "__main__":
    print("helpers for build.py / fitcheck.py / render_all.py; not a CLI", file=sys.stderr)
