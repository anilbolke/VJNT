#!/usr/bin/env python3
"""
review-changes — build a self-contained HTML page for reviewing code changes
file by file (file list, unified / side-by-side diff, "reviewed" ticks).

Python 3 standard library only; needs `git` on PATH. Run it from anywhere
inside the repository (or double-click tools/review-changes.bat).

What to compare (pick one; default = uncommitted work):
  (no option)        working tree vs last commit, incl. new untracked files
  --staged           staged changes only (what the next commit will contain)
  --base main        this branch vs main, i.e. what a PR into main contains
  --commit 24adb32   one commit vs its parent
  --range A..B       any git range

Narrowing / options:
  --path src         only files under these paths (repeatable)
  --exclude PATTERN  skip files matching a glob (repeatable; *.class etc.
                     and Eclipse/Gradle/build/dist noise are skipped by default)
  --all              do not apply the default excludes
  --context N        unchanged lines shown around each change (default 4)
  --strict-eol       show changes that are only CRLF <-> LF (hidden by default)
  -o FILE            where to write the page (default: %TEMP%/review-changes/)
                     (in the page, "Mark all reviewed" / "Clear ticks" act on the
                     files currently listed, so a filter narrows them)
  --no-open          write the page but do not open the browser

Examples:
  python tools/review-changes.py
  python tools/review-changes.py --base main --path src
  python tools/review-changes.py --commit HEAD
"""
import argparse
import datetime
import fnmatch
import hashlib
import html
import json
import os
import re
import subprocess
import sys
import tempfile
import webbrowser

DEFAULT_EXCLUDES = [
    ".gradle/*", ".metadata/*", ".eclipse/*", ".settings/*", "*/.settings/*",
    "dist/*", "build/*", "bin/*", "target/*", "node_modules/*", "*/node_modules/*",
    "*.class", "*.jar", "*.war", "*.log", ".git/*",
]
MAX_LINES_PER_FILE = 6000      # longer diffs are cut, with a notice
MAX_UNTRACKED_BYTES = 2_000_000


def git(args, cwd, check=True):
    p = subprocess.run(["git", *args], cwd=cwd, capture_output=True)
    if check and p.returncode != 0:
        sys.exit("git %s failed:\n%s" % (" ".join(args), p.stderr.decode("utf-8", "replace")))
    return p.stdout


def decode(b):
    return b.decode("utf-8", "replace")


def excluded(path, patterns):
    return any(fnmatch.fnmatch(path, pat) for pat in patterns)


def parse_unified(text):
    """Parse `git diff` output into a list of file dicts."""
    files = []
    cur = None
    hunk = None
    ol = nl = 0
    for line in text.split("\n"):
        if line.startswith("diff --git "):
            m = re.match(r'diff --git "?a/(.+?)"? "?b/(.+?)"?$', line)
            cur = {"old": m.group(1) if m else "", "new": m.group(2) if m else "",
                   "status": "M", "binary": False, "hunks": [], "add": 0, "del": 0}
            files.append(cur)
            hunk = None
            continue
        if cur is None:
            continue
        if hunk is None:
            if line.startswith("new file mode"):
                cur["status"] = "A"
            elif line.startswith("deleted file mode"):
                cur["status"] = "D"
            elif line.startswith("rename from "):
                cur["status"] = "R"; cur["old"] = line[len("rename from "):]
            elif line.startswith("rename to "):
                cur["new"] = line[len("rename to "):]
            elif line.startswith("Binary files ") or line.startswith("GIT binary patch"):
                cur["binary"] = True
        m = re.match(r"@@ -(\d+)(?:,\d+)? \+(\d+)(?:,\d+)? @@ ?(.*)", line)
        if m:
            ol, nl = int(m.group(1)), int(m.group(2))
            hunk = {"header": line, "ctx": m.group(3), "lines": []}
            cur["hunks"].append(hunk)
            continue
        if hunk is None:
            continue
        if line.startswith("\\"):          # "\ No newline at end of file"
            continue
        tag = line[:1]
        body = line[1:].rstrip("\r")
        if tag == "+":
            hunk["lines"].append(["+", None, nl, body]); nl += 1; cur["add"] += 1
        elif tag == "-":
            hunk["lines"].append(["-", ol, None, body]); ol += 1; cur["del"] += 1
        elif tag == " ":
            hunk["lines"].append([" ", ol, nl, body]); ol += 1; nl += 1
    return files


def untracked_file(root, path):
    full = os.path.join(root, path)
    f = {"old": path, "new": path, "status": "A", "binary": False, "hunks": [], "add": 0, "del": 0, "untracked": True}
    try:
        size = os.path.getsize(full)
        if size > MAX_UNTRACKED_BYTES:
            f["binary"] = True; f["note"] = "File too large to show (%d KB)" % (size // 1024)
            return f
        data = open(full, "rb").read()
    except OSError as e:
        f["binary"] = True; f["note"] = str(e)
        return f
    if b"\0" in data[:8000]:
        f["binary"] = True
        return f
    lines = decode(data).split("\n")
    if lines and lines[-1] == "":
        lines.pop()
    f["hunks"] = [{"header": "@@ -0,0 +1,%d @@ (new untracked file)" % len(lines), "ctx": "",
                   "lines": [["+", None, i + 1, l.rstrip("\r")] for i, l in enumerate(lines)]}]
    f["add"] = len(lines)
    return f


def main():
    ap = argparse.ArgumentParser(description="Review changed files in a browser.", formatter_class=argparse.RawDescriptionHelpFormatter, epilog=__doc__)
    g = ap.add_mutually_exclusive_group()
    g.add_argument("--staged", action="store_true")
    g.add_argument("--base")
    g.add_argument("--commit")
    g.add_argument("--range")
    ap.add_argument("--path", action="append", default=[])
    ap.add_argument("--exclude", action="append", default=[])
    ap.add_argument("--all", action="store_true")
    ap.add_argument("--context", type=int, default=4)
    ap.add_argument("--strict-eol", action="store_true")
    ap.add_argument("-o", "--output")
    ap.add_argument("--no-open", action="store_true")
    a = ap.parse_args()

    root = decode(git(["rev-parse", "--show-toplevel"], os.getcwd())).strip()
    branch = decode(git(["rev-parse", "--abbrev-ref", "HEAD"], root)).strip()

    diff_args = ["-c", "core.quotepath=false", "diff", "--no-color", "--no-ext-diff", "-M", "-U%d" % a.context]
    if not a.strict_eol:
        diff_args.append("--ignore-cr-at-eol")
    include_untracked = False
    if a.staged:
        diff_args.append("--cached"); title = "Staged changes"
    elif a.base:
        diff_args.append("%s...HEAD" % a.base); title = "%s vs %s (PR view)" % (branch, a.base)
    elif a.commit:
        sha = decode(git(["rev-parse", "--short", a.commit], root)).strip()
        subj = decode(git(["log", "-1", "--format=%s", a.commit], root)).strip()
        diff_args += ["%s^!" % a.commit]; title = "Commit %s — %s" % (sha, subj)
    elif a.range:
        diff_args.append(a.range); title = "Range %s" % a.range
    else:
        diff_args.append("HEAD"); title = "Uncommitted changes on %s" % branch
        include_untracked = True

    if a.path:
        diff_args += ["--"] + a.path

    files = parse_unified(decode(git(diff_args, root)))
    if include_untracked:
        ls = ["-c", "core.quotepath=false", "ls-files", "--others", "--exclude-standard"] + (["--"] + a.path if a.path else [])
        for p in decode(git(ls, root)).splitlines():
            if p.strip():
                files.append(untracked_file(root, p.strip()))

    patterns = ([] if a.all else DEFAULT_EXCLUDES) + a.exclude
    shown, skipped = [], 0
    for f in files:
        path = f["new"] if f["status"] != "D" else f["old"]
        if excluded(path, patterns):
            skipped += 1
            continue
        if not f["hunks"] and not f["binary"] and f["status"] == "M":
            continue   # e.g. only line endings / mode changed
        f["path"] = path
        n = sum(len(h["lines"]) for h in f["hunks"])
        if n > MAX_LINES_PER_FILE:
            keep, kept = [], 0
            for h in f["hunks"]:
                if kept >= MAX_LINES_PER_FILE:
                    break
                h["lines"] = h["lines"][:MAX_LINES_PER_FILE - kept]
                kept += len(h["lines"]); keep.append(h)
            f["hunks"] = keep
            f["note"] = "Large diff: showing the first %d of %d lines." % (MAX_LINES_PER_FILE, n)
        # Fingerprint so a "reviewed" tick resets when the change itself changes
        f["fp"] = hashlib.sha1(json.dumps(f["hunks"]).encode("utf-8")).hexdigest()[:12]
        shown.append(f)
    shown.sort(key=lambda f: f["path"].lower())

    meta = {
        "title": title, "repo": os.path.basename(root), "branch": branch,
        "generated": datetime.datetime.now().strftime("%Y-%m-%d %H:%M"),
        "skipped": skipped, "command": "python tools/review-changes.py " + " ".join(sys.argv[1:]),
        "key": hashlib.sha1((root + "|" + title).encode("utf-8")).hexdigest()[:10],
    }

    out = a.output
    if not out:
        d = os.path.join(tempfile.gettempdir(), "review-changes")
        os.makedirs(d, exist_ok=True)
        out = os.path.join(d, "review-%s.html" % datetime.datetime.now().strftime("%Y%m%d-%H%M%S"))
    payload = json.dumps({"meta": meta, "files": shown}, ensure_ascii=False).replace("</", "<\\/")
    page = TEMPLATE.replace("__TITLE__", html.escape(title)).replace("__DATA__", payload)
    with open(out, "w", encoding="utf-8") as fh:
        fh.write(page)

    adds = sum(f["add"] for f in shown); dels = sum(f["del"] for f in shown)
    print("%s: %d files (+%d / -%d)%s" % (title, len(shown), adds, dels,
          ", %d skipped by excludes" % skipped if skipped else ""))
    print("Wrote", out)
    if not a.no_open:
        webbrowser.open("file:///" + os.path.abspath(out).replace("\\", "/"))


TEMPLATE = r"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Review — __TITLE__</title>
<style>
:root{--bg:#f6f7f9;--panel:#fff;--text:#1f2328;--muted:#656d76;--border:#d0d7de;--hover:#f3f4f6;--sel:#ddf4ff;
--add-bg:#e6ffec;--add-word:#abf2bc;--add-num:#ccffd8;--del-bg:#ffebe9;--del-word:#ffc0c0;--del-num:#ffd7d5;
--hunk:#ddf4ff;--hunk-text:#0550ae;--accent:#0969da;--ok:#1a7f37;--A:#1a7f37;--M:#9a6700;--D:#cf222e;--R:#8250df;}
@media (prefers-color-scheme:dark){:root{--bg:#0d1117;--panel:#161b22;--text:#e6edf3;--muted:#8d96a0;--border:#30363d;--hover:#1f242c;--sel:#132339;
--add-bg:#12261e;--add-word:#1f5a33;--add-num:#173a27;--del-bg:#2c1416;--del-word:#73282b;--del-num:#42191c;
--hunk:#121d2f;--hunk-text:#79c0ff;--accent:#4493f8;--ok:#3fb950;--A:#3fb950;--M:#d29922;--D:#f85149;--R:#a371f7;}}
*{box-sizing:border-box}
html,body{margin:0;height:100%}
body{background:var(--bg);color:var(--text);font:14px/1.45 -apple-system,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;display:flex;flex-direction:column}
header{background:var(--panel);border-bottom:1px solid var(--border);padding:10px 16px;display:flex;gap:16px;align-items:center;flex-wrap:wrap}
header h1{font-size:16px;margin:0;font-weight:600}
header .sub{color:var(--muted);font-size:12px}
.totals{margin-left:auto;display:flex;gap:12px;align-items:center;font-size:13px}
.plus{color:var(--A);font-weight:600}.minus{color:var(--D);font-weight:600}
.progress{width:120px;height:8px;border-radius:4px;background:var(--border);overflow:hidden}
.progress i{display:block;height:100%;background:var(--ok);width:0}
.layout{flex:1;display:flex;min-height:0}
aside{width:340px;min-width:220px;background:var(--panel);border-right:1px solid var(--border);display:flex;flex-direction:column;resize:horizontal;overflow:auto}
.side-tools{padding:10px;border-bottom:1px solid var(--border);display:flex;flex-direction:column;gap:8px;position:sticky;top:0;background:var(--panel);z-index:2}
input[type=search]{width:100%;padding:7px 10px;border:1px solid var(--border);border-radius:6px;background:var(--bg);color:var(--text);font:inherit}
.chips{display:flex;gap:6px;flex-wrap:wrap}
.chip{border:1px solid var(--border);background:var(--panel);color:var(--text);border-radius:12px;padding:2px 10px;font-size:12px;cursor:pointer}
.chip.on{background:var(--accent);border-color:var(--accent);color:#fff}
.dir{padding:8px 10px 2px;font-size:11px;color:var(--muted);font-weight:600;word-break:break-all}
.f{display:flex;align-items:center;gap:8px;padding:5px 10px 5px 14px;cursor:pointer;border-left:3px solid transparent}
.f:hover{background:var(--hover)}
.f.sel{background:var(--sel);border-left-color:var(--accent)}
.f .st{font:600 11px ui-monospace,Consolas,monospace;width:14px;text-align:center}
.f .nm{flex:1;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.f.done .nm{color:var(--muted);text-decoration:line-through}
.f .ct{font:11px ui-monospace,Consolas,monospace;color:var(--muted);white-space:nowrap}
.f input{margin:0}
main{flex:1;overflow:auto;min-width:0}
.filebar{position:sticky;top:0;z-index:3;background:var(--panel);border-bottom:1px solid var(--border);padding:8px 16px;display:flex;gap:10px;align-items:center;flex-wrap:wrap}
.filebar .path{font:600 13px ui-monospace,Consolas,monospace;word-break:break-all}
.filebar .sp{flex:1}
button{font:inherit;font-size:13px;border:1px solid var(--border);background:var(--panel);color:var(--text);border-radius:6px;padding:4px 10px;cursor:pointer}
button:hover{background:var(--hover)}
button.on{background:var(--accent);color:#fff;border-color:var(--accent)}
.seg{display:inline-flex}.seg button{border-radius:0}.seg button:first-child{border-radius:6px 0 0 6px}.seg button:last-child{border-radius:0 6px 6px 0;border-left:0}
.note{margin:12px 16px;padding:10px 12px;border:1px solid var(--border);border-radius:6px;background:var(--panel);color:var(--muted)}
table.d{width:100%;border-collapse:collapse;font:12.5px/1.5 ui-monospace,SFMono-Regular,Consolas,"Liberation Mono",monospace;table-layout:fixed}
table.d td{padding:0 8px;vertical-align:top;white-space:pre-wrap;word-break:break-all}
td.n{width:52px;text-align:right;color:var(--muted);user-select:none;padding:0 6px;white-space:nowrap}
td.g{width:16px;user-select:none;color:var(--muted);padding:0 2px;text-align:center}
tr.add td.c,tr.add td.g{background:var(--add-bg)} tr.add td.n{background:var(--add-num)}
tr.del td.c,tr.del td.g{background:var(--del-bg)} tr.del td.n{background:var(--del-num)}
td.c.add{background:var(--add-bg)} td.n.add{background:var(--add-num)}
td.c.del{background:var(--del-bg)} td.n.del{background:var(--del-num)}
td.c.empty,td.n.empty{background:var(--hover)}
ins{background:var(--add-word);text-decoration:none;border-radius:2px}
del{background:var(--del-word);text-decoration:none;border-radius:2px}
tr.h td{background:var(--hunk);color:var(--hunk-text);padding:4px 8px}
.split td.c{width:calc(50% - 52px)}
.empty-state{padding:60px 20px;text-align:center;color:var(--muted)}
kbd{border:1px solid var(--border);border-bottom-width:2px;border-radius:4px;padding:0 5px;font-size:11px;background:var(--bg)}
.help{color:var(--muted);font-size:12px}
@media (max-width:800px){.layout{flex-direction:column}aside{width:auto;max-height:40vh;resize:none;border-right:0;border-bottom:1px solid var(--border)}}
</style>
</head>
<body>
<header>
  <div>
    <h1 id="title"></h1>
    <div class="sub" id="sub"></div>
  </div>
  <div class="totals">
    <span id="tot"></span>
    <span id="revCount"></span>
    <div class="progress"><i id="revBar"></i></div>
  </div>
</header>
<div class="layout">
  <aside>
    <div class="side-tools">
      <input type="search" id="q" placeholder="Filter files…  ( / )">
      <div class="chips" id="chips"></div>
    </div>
    <div id="list"></div>
  </aside>
  <main id="main"><div class="empty-state">Select a file</div></main>
</div>
<script id="data" type="application/json">__DATA__</script>
<script>
const DATA = JSON.parse(document.getElementById('data').textContent);
const META = DATA.meta, FILES = DATA.files;
const STORE = 'review-changes:' + META.key;
const ST_NAME = {A:'Added', M:'Modified', D:'Deleted', R:'Renamed'};
let reviewed = {}, view = 'unified', statusOn = new Set(['A','M','D','R']), hideDone = false, cur = -1;
try { reviewed = JSON.parse(localStorage.getItem(STORE) || '{}'); } catch (e) {}
try { view = localStorage.getItem('review-changes:view') || 'unified'; } catch (e) {}

const esc = s => String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
const isDone = f => reviewed[f.path] === f.fp;
function save() { try { localStorage.setItem(STORE, JSON.stringify(reviewed)); } catch (e) {} }

document.getElementById('title').textContent = META.title;
document.getElementById('sub').textContent = META.repo + ' · ' + META.generated +
  (META.skipped ? ' · ' + META.skipped + ' files hidden by excludes (use --all)' : '') + ' · ' + META.command;
const A = FILES.reduce((s,f)=>s+f.add,0), D = FILES.reduce((s,f)=>s+f.del,0);
document.getElementById('tot').innerHTML = FILES.length + ' files <span class="plus">+' + A + '</span> <span class="minus">−' + D + '</span>';

// ---- sidebar ----
const chips = document.getElementById('chips');
['A','M','D','R'].forEach(s => {
  const n = FILES.filter(f => f.status === s).length;
  if (!n) return;
  const b = document.createElement('button');
  b.className = 'chip on'; b.textContent = ST_NAME[s] + ' ' + n;
  b.onclick = () => { statusOn.has(s) ? statusOn.delete(s) : statusOn.add(s); b.classList.toggle('on'); renderList(); };
  chips.appendChild(b);
});
const hd = document.createElement('button');
hd.className = 'chip'; hd.textContent = 'Hide reviewed';
hd.onclick = () => { hideDone = !hideDone; hd.classList.toggle('on'); renderList(); };
chips.appendChild(hd);

// Bulk ticks act on the files currently listed (all of them when nothing is filtered)
function setAll(done) {
  visibleIdx().forEach(i => { const f = FILES[i]; if (done) reviewed[f.path] = f.fp; else delete reviewed[f.path]; });
  save(); renderList();
  if (cur >= 0) show(cur);
}
const ma = document.createElement('button');
ma.className = 'chip'; ma.textContent = '✓ Mark all reviewed';
ma.title = 'Tick every file in the list (respects the current filter)';
ma.onclick = () => setAll(true);
chips.appendChild(ma);
const ca = document.createElement('button');
ca.className = 'chip'; ca.textContent = 'Clear ticks';
ca.title = 'Untick every file in the list (respects the current filter)';
ca.onclick = () => setAll(false);
chips.appendChild(ca);
document.getElementById('q').addEventListener('input', renderList);

function visibleIdx() {
  const q = document.getElementById('q').value.trim().toLowerCase();
  return FILES.map((f,i)=>i).filter(i => {
    const f = FILES[i];
    return statusOn.has(f.status) && (!hideDone || isDone(f) === false || i === cur) && (!q || f.path.toLowerCase().includes(q));
  });
}

function renderList() {
  const list = document.getElementById('list');
  let html = '', lastDir = null;
  visibleIdx().forEach(i => {
    const f = FILES[i], slash = f.path.lastIndexOf('/');
    const dir = slash < 0 ? '(root)' : f.path.slice(0, slash), name = f.path.slice(slash + 1);
    if (dir !== lastDir) { html += '<div class="dir">' + esc(dir) + '</div>'; lastDir = dir; }
    html += '<div class="f' + (i === cur ? ' sel' : '') + (isDone(f) ? ' done' : '') + '" data-i="' + i + '" title="' + esc(f.path) + '">' +
      '<input type="checkbox" ' + (isDone(f) ? 'checked' : '') + ' title="Mark reviewed (r)">' +
      '<span class="st" style="color:var(--' + f.status + ')">' + f.status + '</span>' +
      '<span class="nm">' + esc(name) + '</span>' +
      '<span class="ct">' + (f.binary ? 'bin' : '<span class="plus">+' + f.add + '</span> <span class="minus">−' + f.del + '</span>') + '</span></div>';
  });
  list.innerHTML = html || '<div class="empty-state">No files match</div>';
  list.querySelectorAll('.f').forEach(el => {
    const i = +el.dataset.i;
    el.onclick = e => { if (e.target.tagName === 'INPUT') { toggleDone(i); } else { show(i); } };
  });
  const done = FILES.filter(isDone).length;
  document.getElementById('revCount').textContent = done + ' / ' + FILES.length + ' reviewed';
  document.getElementById('revBar').style.width = (FILES.length ? done * 100 / FILES.length : 0) + '%';
}

function toggleDone(i) {
  const f = FILES[i];
  if (isDone(f)) delete reviewed[f.path]; else reviewed[f.path] = f.fp;
  save(); renderList();
  if (i === cur) { const b = document.getElementById('doneBtn'); if (b) b.classList.toggle('on', isDone(f)), b.textContent = isDone(f) ? '✓ Reviewed' : 'Mark reviewed'; }
}

// ---- intraline highlight: common prefix / suffix ----
function wordDiff(a, b) {
  let p = 0; const n = Math.min(a.length, b.length);
  while (p < n && a[p] === b[p]) p++;
  let s = 0;
  while (s < n - p && a[a.length - 1 - s] === b[b.length - 1 - s]) s++;
  const mid = (str, tag) => esc(str.slice(0, p)) + (str.length - s > p ? '<' + tag + '>' + esc(str.slice(p, str.length - s)) + '</' + tag + '>' : '') + esc(str.slice(str.length - s));
  // Only worth it when the lines share something
  if (p + s < 3) return [esc(a), esc(b)];
  return [mid(a, 'del'), mid(b, 'ins')];
}

// Pair up runs of - then + lines so changed lines sit side by side
function blocks(lines) {
  const out = []; let i = 0;
  while (i < lines.length) {
    if (lines[i][0] === ' ') { out.push({ctx: lines[i]}); i++; continue; }
    const dels = [], adds = [];
    while (i < lines.length && lines[i][0] === '-') dels.push(lines[i++]);
    while (i < lines.length && lines[i][0] === '+') adds.push(lines[i++]);
    out.push({dels, adds});
  }
  return out;
}

function renderUnified(f) {
  let h = '<table class="d">';
  f.hunks.forEach(hk => {
    h += '<tr class="h"><td class="n"></td><td class="n"></td><td class="g"></td><td class="c">' + esc(hk.header) + '</td></tr>';
    blocks(hk.lines).forEach(b => {
      if (b.ctx) { const l = b.ctx; h += '<tr><td class="n">' + l[1] + '</td><td class="n">' + l[2] + '</td><td class="g"></td><td class="c">' + esc(l[3]) + '</td></tr>'; return; }
      const pairs = Math.min(b.dels.length, b.adds.length), dh = [], ah = [];
      b.dels.forEach((l, k) => dh.push(k < pairs ? wordDiff(l[3], b.adds[k][3])[0] : esc(l[3])));
      b.adds.forEach((l, k) => ah.push(k < pairs ? wordDiff(b.dels[k][3], l[3])[1] : esc(l[3])));
      b.dels.forEach((l, k) => h += '<tr class="del"><td class="n">' + l[1] + '</td><td class="n"></td><td class="g">−</td><td class="c">' + dh[k] + '</td></tr>');
      b.adds.forEach((l, k) => h += '<tr class="add"><td class="n"></td><td class="n">' + l[2] + '</td><td class="g">+</td><td class="c">' + ah[k] + '</td></tr>');
    });
  });
  return h + '</table>';
}

function renderSplit(f) {
  let h = '<table class="d split">';
  const cell = (num, txt, cls) => '<td class="n ' + cls + '">' + (num == null ? '' : num) + '</td><td class="c ' + cls + '">' + txt + '</td>';
  f.hunks.forEach(hk => {
    h += '<tr class="h"><td class="n"></td><td class="c" colspan="3">' + esc(hk.header) + '</td></tr>';
    blocks(hk.lines).forEach(b => {
      if (b.ctx) { const l = b.ctx; h += '<tr>' + cell(l[1], esc(l[3]), '') + cell(l[2], esc(l[3]), '') + '</tr>'; return; }
      const n = Math.max(b.dels.length, b.adds.length);
      for (let k = 0; k < n; k++) {
        const d = b.dels[k], a = b.adds[k];
        let dt = d ? esc(d[3]) : '', at = a ? esc(a[3]) : '';
        if (d && a) [dt, at] = wordDiff(d[3], a[3]);
        h += '<tr>' + (d ? cell(d[1], dt, 'del') : cell(null, '', 'empty')) + (a ? cell(a[2], at, 'add') : cell(null, '', 'empty')) + '</tr>';
      }
    });
  });
  return h + '</table>';
}

function show(i) {
  if (i < 0 || i >= FILES.length) return;
  cur = i;
  const f = FILES[i], main = document.getElementById('main');
  const rename = f.status === 'R' ? '<span class="help">renamed from ' + esc(f.old) + '</span>' : '';
  let body;
  if (f.binary) body = '<div class="note">' + esc(f.note || 'Binary file — no text diff.') + '</div>';
  else if (!f.hunks.length) body = '<div class="note">No text changes' + (f.status === 'R' ? ' (pure rename)' : '') + '.</div>';
  else body = (f.note ? '<div class="note">' + esc(f.note) + '</div>' : '') + (view === 'split' ? renderSplit(f) : renderUnified(f));
  main.innerHTML =
    '<div class="filebar">' +
      '<span class="st" style="color:var(--' + f.status + ');font-weight:700">' + ST_NAME[f.status] + (f.untracked ? ' (untracked)' : '') + '</span>' +
      '<span class="path">' + esc(f.path) + '</span>' + rename +
      '<span class="plus">+' + f.add + '</span><span class="minus">−' + f.del + '</span>' +
      '<span class="sp"></span>' +
      '<span class="seg"><button id="vU" class="' + (view === 'unified' ? 'on' : '') + '">Unified</button><button id="vS" class="' + (view === 'split' ? 'on' : '') + '">Side by side</button></span>' +
      '<button id="prevBtn" title="Previous file (k)">↑ Prev</button><button id="nextBtn" title="Next file (j)">Next ↓</button>' +
      '<button id="doneBtn" class="' + (isDone(f) ? 'on' : '') + '" title="r">' + (isDone(f) ? '✓ Reviewed' : 'Mark reviewed') + '</button>' +
      '<button id="copyBtn" title="Copy path">Copy path</button>' +
    '</div>' + body +
    '<div class="help" style="padding:12px 16px"><kbd>j</kbd>/<kbd>k</kbd> next/prev file · <kbd>r</kbd> reviewed · <kbd>n</kbd> next unreviewed · <kbd>s</kbd> toggle view · <kbd>/</kbd> filter</div>';
  document.getElementById('vU').onclick = () => setView('unified');
  document.getElementById('vS').onclick = () => setView('split');
  document.getElementById('prevBtn').onclick = () => step(-1);
  document.getElementById('nextBtn').onclick = () => step(1);
  document.getElementById('doneBtn').onclick = () => toggleDone(cur);
  document.getElementById('copyBtn').onclick = e => { navigator.clipboard && navigator.clipboard.writeText(f.path); e.target.textContent = 'Copied'; };
  main.scrollTop = 0;
  try { history.replaceState(null, '', '#' + encodeURIComponent(f.path)); } catch (e) {}
  renderList();
  const sel = document.querySelector('.f.sel'); if (sel) sel.scrollIntoView({block: 'nearest'});
}

function setView(v) { view = v; try { localStorage.setItem('review-changes:view', v); } catch (e) {} show(cur); }
function step(d) {
  const vis = visibleIdx(); if (!vis.length) return;
  const pos = vis.indexOf(cur);
  show(vis[pos < 0 ? 0 : Math.min(vis.length - 1, Math.max(0, pos + d))]);
}
function nextUnreviewed() {
  for (let k = 1; k <= FILES.length; k++) { const i = (cur + k) % FILES.length; if (!isDone(FILES[i])) return show(i); }
}

document.addEventListener('keydown', e => {
  if (e.target.tagName === 'INPUT' && e.target.type === 'search') { if (e.key === 'Escape') e.target.blur(); return; }
  if (e.ctrlKey || e.metaKey || e.altKey) return;
  if (e.key === 'j') step(1);
  else if (e.key === 'k') step(-1);
  else if (e.key === 'r' && cur >= 0) toggleDone(cur);
  else if (e.key === 'n') nextUnreviewed();
  else if (e.key === 's') setView(view === 'split' ? 'unified' : 'split');
  else if (e.key === '/') { e.preventDefault(); document.getElementById('q').focus(); }
});

renderList();
if (!FILES.length) document.getElementById('main').innerHTML = '<div class="empty-state">No changes to review.</div>';
else {
  const want = decodeURIComponent(location.hash.slice(1));
  const at = FILES.findIndex(f => f.path === want);
  show(at >= 0 ? at : 0);
}
</script>
</body>
</html>
"""

if __name__ == "__main__":
    main()
