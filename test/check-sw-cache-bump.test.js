// Tests for scripts/check-sw-cache-bump.js.
//
// bt-ab14: sw.js's isAppShell() serves navigations/.html/.js network-first,
// so touching tuner.js or an .html page can't go stale from a missed CACHE
// bump the way style.css/manifest.json/icons can — the check must not
// demand a bump for them. The tracked-extension list is parsed out of
// sw.js's own isAppShell() (not hardcoded) so the two can't drift apart.
//
// Runs the real script as a subprocess against a scratch git repo so the
// test exercises the actual git-diffing/regex-parsing behavior end to end.

const { test } = require("node:test");
const assert = require("node:assert/strict");
const { execFileSync } = require("node:child_process");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");

const REAL_SCRIPT = path.join(__dirname, "..", "scripts", "check-sw-cache-bump.js");

const SW_SOURCE = (cache) => `// Service worker — offline shell + version-controlled cache.
const CACHE = "${cache}";
const ASSETS = ["/", "/index.html", "/style.css", "/tuner.js", "/manifest.json", "/icon-192.png"];

function isAppShell(request) {
  if (request.mode === "navigate") return true;
  return request.url.endsWith(".html") || request.url.endsWith(".js");
}

self.addEventListener("fetch", (e) => {});
`;

function sh(cwd, cmd) {
  return execFileSync("sh", ["-c", cmd], { cwd, encoding: "utf8" });
}

function makeRepo() {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "sw-cache-bump-test-"));
  sh(dir, "git init -q -b main");
  sh(dir, 'git config user.email "test@test.local"');
  sh(dir, 'git config user.name "Test"');

  fs.mkdirSync(path.join(dir, "scripts"));
  fs.copyFileSync(REAL_SCRIPT, path.join(dir, "scripts", "check-sw-cache-bump.js"));
  fs.writeFileSync(path.join(dir, "sw.js"), SW_SOURCE("tuner-v1"));
  fs.writeFileSync(path.join(dir, "tuner.js"), "console.log('v1');\n");
  fs.writeFileSync(path.join(dir, "style.css"), "body { color: red; }\n");
  fs.writeFileSync(path.join(dir, "index.html"), "<html>v1</html>\n");

  sh(dir, "git add -A && git commit -q -m base");
  return dir;
}

function runCheck(dir) {
  try {
    const out = execFileSync("node", ["scripts/check-sw-cache-bump.js"], {
      cwd: dir,
      encoding: "utf8",
      env: { ...process.env, GITHUB_BASE_REF: "", GITHUB_EVENT_BEFORE: "" },
    });
    return { status: 0, out };
  } catch (err) {
    return { status: err.status, out: (err.stdout || "") + (err.stderr || "") };
  }
}

test("JS-only change (network-first asset): passes without a CACHE bump", () => {
  const dir = makeRepo();
  fs.writeFileSync(path.join(dir, "tuner.js"), "console.log('v2');\n");
  sh(dir, "git commit -aqm 'change tuner.js, no CACHE bump'");

  const { status, out } = runCheck(dir);
  assert.equal(status, 0, out);
});

test("HTML-only change (network-first asset): passes without a CACHE bump", () => {
  const dir = makeRepo();
  fs.writeFileSync(path.join(dir, "index.html"), "<html>v2</html>\n");
  sh(dir, "git commit -aqm 'change index.html, no CACHE bump'");

  const { status, out } = runCheck(dir);
  assert.equal(status, 0, out);
});

test("style.css change (still cache-first): fails without a CACHE bump", () => {
  const dir = makeRepo();
  fs.writeFileSync(path.join(dir, "style.css"), "body { color: blue; }\n");
  sh(dir, "git commit -aqm 'change style.css, no CACHE bump'");

  const { status, out } = runCheck(dir);
  assert.equal(status, 1, out);
  assert.match(out, /CACHE.*not bumped/);
});

test("style.css change: passes once sw.js and its CACHE are bumped together", () => {
  const dir = makeRepo();
  fs.writeFileSync(path.join(dir, "style.css"), "body { color: blue; }\n");
  fs.writeFileSync(path.join(dir, "sw.js"), SW_SOURCE("tuner-v2"));
  sh(dir, "git commit -aqm 'change style.css and bump CACHE'");

  const { status, out } = runCheck(dir);
  assert.equal(status, 0, out);
});
