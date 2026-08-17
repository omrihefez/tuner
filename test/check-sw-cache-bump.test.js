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
//
// bt-f541: EVERY git call below must run with the GIT_* environment stripped
// (gitEnv()). mkdtempSync() isolation is necessary but NOT sufficient, because
// GIT_DIR and friends OUTRANK the process cwd — and `git push` from a LINKED
// WORKTREE exports GIT_DIR=<repo>/.git/worktrees/<name> to the pre-push hook
// (a push from the main checkout does not, which is why this went unnoticed).
// The hook then runs `npm test`, so every git call here inherits it. With
// GIT_DIR set and GIT_WORK_TREE unset, git treats the PROCESS CWD as the work
// tree, so against the real repo: makeRepo()'s `git init` re-inits it and,
// having no work tree of its own, sets core.bare=true on it; `git add -A &&
// git commit` then lands the fixture's 4 synthetic files on the real
// checked-out branch, replacing the entire tracked tree. That is exactly what
// happened on 2026-08-18 — origin/main was overwritten with this file's
// fixture history ("base" / "change tuner.js, no CACHE bump") and
// bass.omrihefez.com served the fixture's `<html>v1</html>`.

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

// A copy of process.env with every GIT_* variable removed, so `cwd` is the
// only thing that decides which repository a git call operates on. Deliberately
// a prefix sweep rather than a list of known-dangerous names (GIT_DIR,
// GIT_WORK_TREE, GIT_INDEX_FILE, GIT_OBJECT_DIRECTORY, GIT_COMMON_DIR,
// GIT_NAMESPACE, GIT_CONFIG_*, ...): a denylist has to be kept in step with
// git's own additions, and the failure mode of missing one is this incident.
// Nothing in this test needs a GIT_* variable, so drop them all.
function gitEnv(extra = {}) {
  const env = { ...process.env, ...extra };
  for (const key of Object.keys(env)) {
    if (key.startsWith("GIT_")) delete env[key];
  }
  return env;
}

function sh(cwd, cmd) {
  return execFileSync("sh", ["-c", cmd], { cwd, encoding: "utf8", env: gitEnv() });
}

// The safety net, independent of WHY an escape might happen: make git itself
// say which repository it resolves from the fixture dir, and refuse to run a
// single mutating command unless the answer is the one we expect. gitEnv()
// closes the mechanism we know about; this closes the class — a future escape
// (a GIT_* variable git adds later, a stray includeIf in a global config, an
// inherited cwd) then costs a red test instead of the host repo's tracked tree.
//
// Checked on BOTH sides of `git init`, because `git init` is itself one of the
// destructive commands: run with an ambient GIT_DIR it re-inits that repo and
// flips core.bare on it, which is how the real checkout ended up refusing every
// command with "fatal: this operation must be run in a work tree".
function resolveGitDir(dir) {
  try {
    return execFileSync("git", ["rev-parse", "--absolute-git-dir"], {
      cwd: dir,
      encoding: "utf8",
      env: gitEnv(),
      stdio: ["ignore", "pipe", "ignore"],
    }).trim();
  } catch {
    return null; // not inside a repository — which is what we want pre-init
  }
}

function escaped(dir, resolved, expected) {
  return new Error(
    `fixture escaped its sandbox: git in ${dir} resolved to ${resolved ?? "<none>"}, expected ${expected}. ` +
      `Refusing to run git commands that would mutate a real repository (bt-f541).`,
  );
}

// A freshly-mkdtemp'd dir under os.tmpdir() is not inside any repository, so
// git resolving ANYTHING here means it came from outside — abort before
// `git init` can touch it.
function assertNoAmbientRepo(dir) {
  const resolved = resolveGitDir(dir);
  if (resolved !== null) throw escaped(dir, resolved, "no repository at all");
}

function assertIsolated(dir) {
  const resolved = resolveGitDir(dir);
  const expected = path.join(fs.realpathSync(dir), ".git");
  if (resolved === null || fs.realpathSync(resolved) !== expected) {
    throw escaped(dir, resolved, expected);
  }
}

function makeRepo() {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "sw-cache-bump-test-"));
  assertNoAmbientRepo(dir);
  sh(dir, "git init -q -b main");
  assertIsolated(dir);
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
      // gitEnv(), not { ...process.env }: the script under test runs `git diff`
      // itself, so an inherited GIT_DIR would point IT at the real repo too.
      env: gitEnv({ GITHUB_BASE_REF: "", GITHUB_EVENT_BEFORE: "" }),
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

// bt-f541 regression. Builds a stand-in for the real checkout, poisons GIT_DIR
// exactly as a pre-push hook does, runs this file's own fixture machinery, and
// asserts the stand-in survived it.
//
// Run against BOTH poison forms, because they do NOT fail the same way and the
// quiet one is the dangerous one:
//
//   .git/worktrees/<name>  what a push from a LINKED WORKTREE actually exports.
//                          init can infer no work tree, so it sets core.bare on
//                          the victim and the FIXTURE cwd becomes the work
//                          tree — the victim's tree is replaced wholesale
//                          (bass-tuner: 229 files -> 5). Loud.
//
//   .git                   init infers the parent as a valid work tree, so the
//                          victim stays non-bare and add/commit operate on its
//                          REAL tree: a bogus commit lands on the checked-out
//                          branch while core.bare AND the tracked-file count
//                          both stay clean. Only HEAD betrays it. Quiet.
//
// Hence: HEAD is the load-bearing assertion. core.bare and the file count are
// worktree-form side effects, and a fix validated on those alone passes green
// while the quiet form still escapes.
for (const [label, poisonOf] of [
  ["linked-worktree gitdir", (host) => path.join(host, ".git", "worktrees", "wt")],
  ["plain gitdir", (host) => path.join(host, ".git")],
]) {
  test(`fixture git operations cannot escape into an ambient GIT_DIR (${label})`, () => {
    const host = fs.mkdtempSync(path.join(os.tmpdir(), "sw-cache-bump-host-"));
    sh(host, "git init -q -b main");
    sh(host, 'git config user.email "host@test.local"');
    sh(host, 'git config user.name "Host"');
    fs.writeFileSync(path.join(host, "app.js"), "REAL APP\n");
    fs.mkdirSync(path.join(host, "docs"));
    fs.writeFileSync(path.join(host, "docs", "readme.md"), "REAL DOCS\n");
    sh(host, "git add -A && git commit -q -m 'real work'");
    sh(host, `git worktree add -q ${JSON.stringify(path.join(host, "wt"))} -b feature`);

    // `feature` for the worktree form, `main` for the plain form: each is the
    // branch that form's inferred work tree actually has checked out, so each
    // is the branch a bogus commit would land on.
    const branch = label === "plain gitdir" ? "main" : "feature";
    const before = {
      head: sh(host, `git rev-parse ${branch}`).trim(),
      tree: sh(host, `git ls-tree -r --name-only ${branch}`),
      bare: sh(host, "git config --get core.bare").trim(),
    };
    assert.equal(before.bare, "false"); // guards the assertion below from vacuity

    const restore = process.env.GIT_DIR;
    process.env.GIT_DIR = poisonOf(host);
    try {
      const dir = makeRepo();
      fs.writeFileSync(path.join(dir, "style.css"), "body { color: blue; }\n");
      sh(dir, "git commit -aqm 'change style.css, no CACHE bump'");
      const { status } = runCheck(dir);
      assert.equal(status, 1); // the check still works normally under the poison
    } finally {
      if (restore === undefined) delete process.env.GIT_DIR;
      else process.env.GIT_DIR = restore;
    }

    assert.equal(sh(host, `git rev-parse ${branch}`).trim(), before.head, "host HEAD moved");
    assert.equal(sh(host, `git ls-tree -r --name-only ${branch}`), before.tree, "host tree rewritten");
    assert.equal(sh(host, "git config --get core.bare").trim(), before.bare, "host core.bare flipped");
  });
}
