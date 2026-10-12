---
id: bt-6854
title: Locking a string didn't constrain the detector, so a locked G read 49Hz (half of 98, on top
  of 50Hz hum) and the needle jumped — drop D hit hardest
status: done
priority: p1
tags:
  - from-omri
  - pitch-detection
created: 2026-10-11
filed:
  owner: omri@ubuntu-4gb-nbg1-1
  at: 2026-10-11T19:59:56Z
done:
  at: 2026-10-11T20:00:09Z
  by: omri@ubuntu-4gb-nbg1-1
evidence:
  - type: commit
    value: 024a401
    verified: 2026-10-11T20:00:09Z
  - type: test
    cmd: cd /home/omri/projects/bass-tuner && node --test test/locked-string-range.test.js
    exit: 0
    at: 2026-10-11T20:00:09Z
    log: evidence/bt-6854-2026-10-11T20-00-09Z-test.txt
    sha256: d7bf416e3604f2e5f491384af39cc3a38eeee1b8961a39ae91c5ed7cfee72625
    bytes: 1253
    expect: pass 5
  - type: live
    cmd: curl -s --max-time 10 https://bass.omrihefez.com/tuner.js | grep -c LOCK_RANGE_SEMITONES
    exit: 0
    at: 2026-10-11T20:00:09Z
    log: evidence/bt-6854-2026-10-11T20-00-09Z-live.txt
    sha256: 39495594a90985fde100cd06091cdaa9e1d97f7ece1035f788f4ebd4838eda1d
    bytes: 94
    expect: "4"
---

HIS WORDS, 2026-10-11 22:49 IDT, while tuning drop D with the bass in his hands:
"Man the tuner app is not behaving. I'm trying to tune drop d. The high g and d
don't behave. I play the g on the bass and it shows much lower freqs. Keep
jumping even when I lock the g"

## Cause — one defect producing both halves of his report

`state.selectedString` fed only the `idx` pick in the display path
(tuner.js ~545): it chose which string the reading was compared *against*, and
did nothing to constrain what the detector was allowed to *return*.
`freqRange()` derived its window from every note in the current tuning, so a
locked G2 (98 Hz) still let YIN pick anything in drop D's ~[31,131] Hz —
including **49 Hz, exactly half of 98**, which also sits a whisker from the
50 Hz mains hum an amp feeds into the mic. The reading flipped between 98 and
49; at 49 against a G target that is −1200 cents, so the needle slammed to the
rail. "Shows much lower freqs" and "keeps jumping even when I lock" are the
same bug.

Drop D is hit harder than standard, exactly as he noticed: its lowest note is
D1 (36.71 Hz) against standard's E1 (41.20), so the search window opens ~4 Hz
lower and more of the hum's harmonic series falls inside the range YIN may
choose from. The mains-hum note in tuner.js already records this mechanism for
½-step down (that was his 2026-08-29 report) — drop D is the same shape and
nobody extended the reasoning to it.

## Fix

Locked, `freqRange()` returns the locked string's own target ±6 semitones. For
G2 that is 69–139 Hz: neither 49 Hz nor 50 Hz hum is a candidate. Auto-detect
is byte-for-byte unchanged.

±6 rather than tighter because he is usually mid-retune while locked — dropping
E→D is two semitones and a slack string on the way there reads lower still. A
tritone covers any real detune while excluding both the half and the double
(±12) by a 6-semitone margin. Tighter would start refusing to read a string he
is actively slackening, which is the one job locking has.

## Why it shipped — the coverage gap, not just the bug

`test/mains-hum.test.js`'s "every string detects under amp hum, in every
tuning" looks like total coverage and **never sets `state.selectedString`**, so
it only ever exercised auto-detect. The locked path had no test at all.

`test/locked-string-range.test.js` covers it now: per string, per tuning, that
each locked window excludes its own half and double; that a string mid-retune
(E1 while locked to D1, and four semitones slacker) still reads; that the
unlocked range is unchanged; and that an out-of-range index falls back to the
whole-tuning window.

## Verification

- New test **proven to fail before the fix**: removing only the lock branch
  takes it to 3 of 5 failing; restored, 5/5.
- Full suite 126/126, `npm run build` clean, pre-push gate green.
- Live on `bass.omrihefez.com` 22:59:15 IDT, verified by fetching the served
  `tuner.js` and grepping for `LOCK_RANGE_SEMITONES` (4 occurrences), site 200.
- No SW cache bump needed: `isAppShell()` treats every `.js` as network-first,
  so it is live on his next load rather than waiting on a `CACHE` version move.

Committed in the main worktree under `DONEFILE_ALLOW_MAIN_COMMIT=1` with the
guard's condition verified, not assumed: 0 active worker sessions fleet-wide,
none on this board, and the only uncommitted paths in the repo were these two.
He was waiting at the bass, so a worktree round-trip was not worth the minutes.

## Log
- 2026-10-11 done by omri@ubuntu-4gb-nbg1-1 — commit 024a401, test `cd /home/omri/projects/bass-tuner && node --test test/locked-string-range.test.js` exit 0 (--test-expect "pass 5") (log: evidence/bt-6854-2026-10-11T20-00-09Z-test.txt), live `curl -s --max-time 10 https://bass.omrihefez.com/tuner.js | grep -c LOCK_RANGE_SEMITONES` exit 0 (--live-expect "4") (log: evidence/bt-6854-2026-10-11T20-00-09Z-live.txt)
- 2026-10-12 TOLD-OMRI: hub message 68873 at 2026-10-11 22:59 IDT — Fixed and live — reload the tuner and try drop D again.
