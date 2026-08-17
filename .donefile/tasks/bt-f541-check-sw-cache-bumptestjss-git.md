---
id: bt-f541
title: "check-sw-cache-bump.test.js's git isolation is broken: a pre-push npm test run wiped and
  overwrote production main with test fixture content"
status: done
priority: p0
tags:
  - reliability
  - incident
  - ci
created: 2026-08-18
done:
  at: 2026-08-17T21:58:35Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: 9a27a53
    verified: 2026-08-17T21:58:35Z
  - type: test
    cmd: cd /home/omri/projects/bass-tuner && node --test test/check-sw-cache-bump.test.js
    exit: 0
    at: 2026-08-17T21:58:34Z
    log: evidence/bt-f541-2026-08-17T21-58-34Z-test.txt
    sha256: a5d6a4151a3ddfa0e1f0f55f8154bfea3fc7db199e05d6bf1e0ec2d190f20968
    bytes: 1558
---

INCIDENT, 2026-08-18 ~00:16-00:36 IDT. During a routine `git push origin <branch>:main`
(landing an unrelated scripts/lib/ change, ma-a861), the client-side pre-push hook ran
`npm test`, which includes test/check-sw-cache-bump.test.js. That test's makeRepo()
helper is supposed to git-init an isolated fs.mkdtempSync() fixture per test case
(confirmed reading the source: it does use os.tmpdir()/mkdtempSync, TMPDIR resolves
to a normal /tmp on this box) — but during this run its git operations landed in the
REAL worktree instead of the fixture dir, replacing the tracked tree (225 files: the
whole app, docs, donefile board, evidence) with the test's own synthetic 4-file
fixture history (commits titled "base" / "change tuner.js, no CACHE bump" / etc).
Root cause NOT diagnosed — the source read as correctly isolated, so this may be an
environment interaction (concurrent worktree use, TMPDIR/cwd race, node --test
parallelism) rather than a straightforward bug in the test file itself.

IMPACT: git push (which runs after the hook approves) sent that corrupted tree to
origin/main (2a1fe77..b907eaf, "17987 deletions(+), 6 insertions(-)"). bass-tuner's
Vercel project is git-integrated (auto-deploy on push to main), so bass.omrihefez.com
briefly served the fixture's `<html>v1</html>` (confirmed via curl) instead of the
real tuner app — a real user-facing outage, not just a git-history problem.

Separately, the SAME `npm test` run also somehow left the MAIN checkout's
(/home/omri/projects/bass-tuner) .git/config with `core.bare = true`, making every
git command there fail with "fatal: this operation must be run in a work tree" until
I set `git config core.bare false` by hand. Not yet understood how a worktree's test
run could touch the shared repo config's core.bare — flagging as part of the same
incident since it appeared at the same time, but it may be a distinct mechanism.

REMEDIATION (done): restored origin/main via a NEW fast-forward commit (bf1e5c0,
tree-identical to what SHOULD have been pushed) — no force-push, no history rewrite.
Verified bass.omrihefez.com now serves the real app (3200-byte index.html, correct
<title>, tuner.js has real pitch-detection code). Fixed core.bare locally. Did NOT
re-run npm test against the real worktree again (used --no-verify for the restore
push specifically to avoid re-triggering the same corruption) — so the underlying
test-isolation bug is UNCONFIRMED-FIXED and could fire again on the next normal push
that runs the full pre-push suite.

DONE WHEN: the actual mechanism by which check-sw-cache-bump.test.js (or something
alongside it) escaped its mkdtemp isolation is identified and fixed, OR the pre-push
hook is changed to run that test suite in a way that cannot touch the real worktree
regardless of the bug (e.g. run node --test in a fully separate clone), and a normal
`git push` (going through the real hook, no --no-verify) no longer risks repeating
this.

## Log
- 2026-08-18 Same failure class as tonight's two path bugs, per Main's review: dn-b3b6
(evidence rooted in a worktree that later vanishes) and dn-d05d
(install-hooks baking a path that stops existing) are both "a path assumed
stable turned out not to be." This one is the most dangerous variant of that
class: it is not a stale reference failing closed later, it is a test
escaping its own sandbox and operating on the REAL worktree while it still
exists — so the blast radius is production (a live Vercel deploy), not a
broken reference. Whoever picks this up should treat "does my fixture path
actually stay inside the fixture" as the first thing to verify, not assume
mkdtemp() alone guarantees it (this repo's code reads as correctly isolated
and still failed).
- 2026-08-18 claimed by capacity-engine
- 2026-08-18 ROOT CAUSE FOUND AND REPRODUCED. Not an environment race, not node --test
parallelism, and mkdtempSync() was never the weak link — the ENVIRONMENT was.

`git push` from a LINKED WORKTREE exports GIT_DIR=<repo>/.git/worktrees/<name>
to the pre-push hook. A push from the MAIN checkout does not — verified both
ways on git 2.43.0 — which is exactly why this test sat here safely for weeks
and then fired the first time someone pushed from a worktree.

The hook runs `npm test`, so every git call in check-sw-cache-bump.test.js
inherited that GIT_DIR. GIT_DIR outranks cwd, and with GIT_WORK_TREE unset git
treats the PROCESS CWD as the work tree. So, against the real repo:
  - makeRepo()'s `git init` re-inits it ("warning: re-init") and, having no
    work tree of its own, sets core.bare=true on it -> that is the second,
    "not yet understood" symptom in this report, same mechanism, not distinct.
  - `git config user.email/name` writes to the real repo's config.
  - `git add -A && git commit` stages the FIXTURE dir as the work tree and
    lands its files on the real checked-out branch, replacing the tracked tree.

Reproduced end to end on a throwaway clone of this repo, running the REAL
pre-push hook, pushing from a real linked worktree. Pre-fix control run:
core.bare flipped false->true, branch tree went 229 files -> 5, and the log
read "change style.css and bump CACHE" / "base" / "change style.css, no CACHE
bump" — the exact commit titles from the incident. Post-fix run on the same
setup: 105/105 tests pass, push exits 0, repo untouched (229 files,
core.bare=false).

FIX (9a27a53):
  - gitEnv() strips every GIT_* var from the env of every git call, including
    runCheck()'s (the script under test runs `git diff` itself, so it was
    being pointed at the real repo too). Prefix sweep, not a denylist —
    missing one name is how this happened.
  - assertNoAmbientRepo()/assertIsolated() bracket `git init` and make git
    itself name the repo it resolved. `git init` needs the check on BOTH
    sides because it is itself one of the destructive commands. This closes
    the CLASS, not just the known mechanism: any future escape (a GIT_* var
    git adds later, a stray includeIf, an inherited cwd) now costs a red test
    instead of the host repo's tree.
  - Regression test builds a repo WITH a linked worktree, poisons GIT_DIR
    exactly as the hook does, and asserts the stand-in's HEAD, tree and
    core.bare all survive. Verified it fails destructively against the
    pre-fix file ("host HEAD moved") and passes after.

SECOND DEFECT FOUND while verifying, fixed in the same commit: the installed
pre-push hook's default gate is `npm run build && npm test`, and this repo had
no `build` script, so npm exited 1 and the hook REFUSED EVERY non-bookkeeping
push. That is not a cosmetic gap — a gate that always fails is precisely the
pressure that gets the next person to reach for --no-verify, which is how the
corrupted tree reached origin in the first place. `npm run build` now runs the
offline half of ci.yml's static-checks job (syntax / links / cache-bump), so
the local gate mirrors CI instead of dying on it.
Sharp edge worth remembering: check:syntax uses `xargs -n1` because
`node --check a.js b.js` silently checks only a.js and exits 0 — both
`-exec {} +` and `-exec {} \;` produce a syntax check that CANNOT FAIL.
Verified falsifiable: exit 0 clean, exit 123 with a deliberately broken file.

DONE WHEN satisfied end to end: this branch was landed by a normal
`git push origin bt-f541-test-git-isolation:main` from a linked worktree,
through the real hook, NO --no-verify. Hook ran build + 105 tests, push exit 0,
4c2f5de..9a27a53. Main checkout after: core.bare=false, tree intact.
bass.omrihefez.com still serves the real app (200, 3200 bytes,
"<title>Tuner — bass & guitar, ad-free</title>").
- 2026-08-18 done by capacity-engine/worker — commit 9a27a53, test `cd /home/omri/projects/bass-tuner && node --test test/check-sw-cache-bump.test.js` exit 0 (log: evidence/bt-f541-2026-08-17T21-58-34Z-test.txt)
