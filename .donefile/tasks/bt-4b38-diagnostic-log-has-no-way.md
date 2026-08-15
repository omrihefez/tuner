---
id: bt-4b38
title: Diagnostic log has no way off the device — no copy, share or beacon, so the on-page panel
  cannot help the open client-side p1
status: done
priority: p2
tags:
  - dx
  - observability
  - pwa
created: 2026-08-15
done:
  at: 2026-08-15T15:22:53Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: 02cf875
    verified: 2026-08-15T15:22:53Z
  - type: test
    cmd: cd /home/omri/projects/bass-tuner && npm test
    exit: 0
    at: 2026-08-15T15:22:51Z
    log: evidence/bt-4b38-2026-08-15T15-22-51Z-test.txt
    sha256: 1170a8f51d5e1443a61155f9bede4d2bc4a7b7d1b7d1a16b1aa6f9f7a74b1c69
    bytes: 22285
  - type: live
    cmd: bash /home/omri/projects/bass-tuner/deploy/activation-probes/probe-bt-5fb7.sh 02cf875
      https://bass.omrihefez.com/sw.js
    exit: 0
    at: 2026-08-15T15:22:51Z
    log: evidence/bt-4b38-2026-08-15T15-22-51Z-live.txt
    sha256: 468fc73142ae55526e43744ed4d7beb40541a37681721e7e25a6442a5d275525
    bytes: 195
---

The tuner has real client-side diagnostics and no way to get them off the device they
were captured on.

WHAT EXISTS (tuner.js:623-645): a `diag()` logger that captures page errors
(`window.addEventListener("error")`), unhandled rejections, protocol/host, userAgent, and
mediaDevices/getUserMedia availability. It is gated off by default —

    const DIAG_ENABLED = /(^|[?&])debug(=|&|$)/.test(location.search || "") ||
      localStorage.getItem("tuner:debug") === "1";

— which is right, since it echoes the userAgent.

WHAT IS MISSING: the sink. `diag()` appends to `document.getElementById("diag-log")`, and
index.html:76-78 is the whole of it:

    <details class="diag" id="diag-panel" hidden>
      ...
      <pre id="diag-log"></pre>

`grep -n "diag-panel|diag-log|clipboard|share|copy" index.html tuner.js` returns four
lines, all of them the above. There is no copy button, no `navigator.clipboard` call, no
Web Share invocation, no beacon, no upload — nothing. The only route from that `<pre>` to
anyone who could act on it is the person holding the phone hand-selecting scrolled text
inside a `<pre>` inside a collapsed `<details>`, or screenshotting it.

WHY IT MATTERS RIGHT NOW: bt-b7e7 is open at p1 — "Tuner stopped working on his device —
server, deploy and code all verified healthy, cause is client-side". That is precisely the
bug class this logger was built for (its own comment says "Helps debug why mic prompt
isn't appearing on a real device"), and the reason it cannot help is that its output has
nowhere to go. Adding the sink is what makes the next round of that p1 a data question
instead of another round of guessing.

SCOPE — deliberately the small version. A one-tap "Copy diagnostics" button inside the
existing debug panel (`navigator.clipboard.writeText`, with a `navigator.share` path where
available and a select-all fallback where neither exists) so he can paste the log into the
app thread in one action. NOT a telemetry endpoint: this app has no backend, no consent
flow and no privacy.html language for uploading anything, and auto-reporting would need a
deliberate product decision rather than a bug fix. Keep it behind the same DIAG_ENABLED
gate so nothing changes for normal users.

Worth including in the copied payload while touching this: the current CACHE version from
the active service worker registration and the app's own build/deploy marker if one is
reachable, since "which bundle is his device actually running" is the first question any
client-side report raises and the diag block does not answer it today.

DONE WHEN: with `?debug` (or `localStorage["tuner:debug"]="1"`) set, the diagnostic panel
offers a single control that puts the full log text on the clipboard (or into the share
sheet) on one tap, verified on a real mobile browser; the payload includes the active
service-worker cache version; nothing about the default, non-debug experience changes; and
a test covers that the control is absent when DIAG_ENABLED is false.

VERIFY: `cd /home/omri/projects/bass-tuner && node --test test/` green with the new case,
plus a screenshot of the panel with the control visible under `?debug` and absent without
it — committed under `.donefile/evidence/`, not left in a worktree.

## Log
- 2026-08-15 claimed by capacity-engine
- 2026-08-15 done by capacity-engine/worker — commit 02cf875, test `cd /home/omri/projects/bass-tuner && npm test` exit 0 (log: evidence/bt-4b38-2026-08-15T15-22-51Z-test.txt), live `bash /home/omri/projects/bass-tuner/deploy/activation-probes/probe-bt-5fb7.sh 02cf875 https://bass.omrihefez.com/sw.js` exit 0 (log: evidence/bt-4b38-2026-08-15T15-22-51Z-live.txt)
