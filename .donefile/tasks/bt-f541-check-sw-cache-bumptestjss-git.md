---
id: bt-f541
title: "check-sw-cache-bump.test.js's git isolation is broken: a pre-push npm test run wiped and
  overwrote production main with test fixture content"
status: claimed
priority: p0
tags:
  - reliability
  - incident
  - ci
created: 2026-08-18
claim:
  owner: capacity-engine
  at: 2026-08-17T21:48:13Z
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
