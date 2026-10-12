---
id: bt-59c4
title: "bass-tuner: port meni-arch's crontab empty-read guard to its 4 cron installer(s) — a failed
  crontab -l replaces the whole 222-entry table"
status: open
priority: p2
tags:
  - reliability
  - cross-board
created: 2026-10-12
filed:
  owner: omri@ubuntu-4gb-nbg1-1
  at: 2026-10-12T16:48:18Z
---

## What to do

Port meni-arch's empty-read guard to this repo's cron installers. 4 file(s) here still carry the
unguarded shape `current="$(crontab -l 2>/dev/null || true)"`, measured 2026-10-12.

Find them: `grep -rln 'crontab -l 2>/dev/null || true' --include='*.sh' .`

## Why it matters (do not re-derive this, it is settled)

`|| true` collapses a FAILED `crontab -l` into the same empty value as a legitimately empty
crontab. The installer then strips its own marker block from that empty string and pipes the
result back into `crontab -` — replacing the box's entire table (222 entries) with just this
installer's block. Tagged data-loss for that reason. On meni-arch the wiped lines included the
prod and preview deploy crons, so a failed read during an unrelated install silently disabled
production auto-deploy with every surface still reporting success.

## Reference implementation — port it, do not invent one

meni-arch commit 4d45bf2 (task ar-9eb3). Verified by Main: its
`scripts/crontab-empty-read-guard.test.sh` runs 20 hermetic checks across 5 installers, stubbing
the `crontab` binary so it needs no real crontab, and covers all three read states
(fails / succeeds-empty / succeeds-with-content) plus the no-regression case
"normal install preserves existing unrelated entries".

Shape:
  - shared sourced lib `scripts/lib/crontab-empty-read-guard.sh` exposing
    `crontab_install_read_or_refuse`, called as
    `current="$(crontab_install_read_or_refuse "$ALLOW_EMPTY_BASE")" || exit 1`
  - the installer FAIL-CLOSES if that lib cannot be sourced
  - a genuine first install is allowed only behind an EXPLICIT `--allow-empty-base` flag,
    stripped from the args before the --print/--print-line/--remove dispatch so it composes with
    all of them, and NEVER inferred from the empty read itself. That last point is the whole fix:
    the bug is precisely that an empty read is indistinguishable from a failed one, so the opt-in
    has to come from the caller.

Do NOT use meni-music/jobs/install-crons.sh as the model. It refuses correctly but has no opt-in
flag and no test, so porting it would break a genuine first install.

## Keep the capture, fix only the fallback

Do not simply delete `|| true`, and do not treat the capture-into-a-variable idiom as the bug.
meniapp's check-crontab-lock-idiom-drift.sh prescribes that capture for a real separate reason
(ma-518c, in its own header): `crontab -l` is ~69KB, over the 64KB pipe buffer, so piping it into
`grep -q` lets the consumer exit on first match and SIGPIPE the producer, and `set -o pipefail`
then promotes that into a reported "not found" — inverting the answer. That advice stays.

## Acceptance (must cut both ways)
  - `crontab -l` fails or returns empty while a real crontab exists -> installer REFUSES,
    non-zero exit, table untouched. Assert the pre-existing entries are still present afterwards.
  - genuine first install with `--allow-empty-base` -> proceeds.
  - normal install over existing content -> unrelated entries preserved (no regression).
  Copy meni-arch's test rather than writing a new one; it already stubs `crontab` hermetically.

## Provenance
Split out by Main from ar-b181 (meni-arch), which named ten repos in one title, was deduped
against by eight other boards at 100%, and was then falsely closed on meni-arch's own commit —
retiring every other repo's work at once. One task per board so each is closable by that repo's
own commit. Root/diagnosis tasks: ma-a745 (meniapp), hc-2b70 (house-control).


cross-board: names a file under 'meni-music' at /home/omri/projects/meni-music — consider filing there instead (see dn-334c).

## Log
- 2026-10-12 title: 'Port meni-arch's crontab empty-read guard to this repo's 4 cron installer(s) — a failed crontab -l wipes the whole table' -> 'bass-tuner: port meni-arch's crontab empty-read guard to its 4 cron installer(s) — a failed crontab -l replaces the whole 222-entry table'
