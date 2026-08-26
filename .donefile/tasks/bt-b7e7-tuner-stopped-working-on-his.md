---
id: bt-b7e7
title: Tuner stopped working on his device — server, deploy and code all verified healthy, cause is
  client-side
status: open
priority: p1
tags:
  - from-omri
  - bug
created: 2026-08-15
---

HIS WORDS, 2026-08-15 00:33 IDT: "Tuner app stopped working. Check it out. Needs fixings now"

WHAT I RULED OUT IMMEDIATELY, all verified live within four minutes:
- bass.omrihefez.com returns 200 in 0.29s; tuner.omrihefez.com still 308-redirects to it correctly.
- /tuner.js (32,356 bytes), /style.css and /manifest.json all return 200 with correct content types, and the served JS ends cleanly — not truncated.
- The deployed tuner.js is byte-for-byte identical to the repo's (same md5), and probe-bt-5fb7 confirms the live cache version matches HEAD (tuner-v10).
- tuner.js has not been modified since 2026-08-01. Nothing deployed this week touched the app's code — this week's bass-tuner commits are all monitoring/cron work.

So the server, the deploy and the code are all healthy. Whatever broke is on his device.

THREE CANDIDATES, in order of likelihood:
1. Microphone permission dropped — commonest cause, and Chrome sometimes drops it after an update. Different path depending on whether he is in the browser or the installed app.
2. Stale service-worker cache — it is a PWA and caches itself, so a bad cached copy can persist across reloads.
3. A leaked mic stream from a previous session holding the device. bt-8e75 fixed the code path that caused that (AudioContext setup throwing AFTER getUserMedia succeeded, leaving the stream open), but a stream held by a backgrounded instance would still block a fresh open. Swiping the app from recents clears it.

WHAT I ASKED HIM FOR: which symptom exactly (blank screen vs needle dead vs needle jumping vs no permission prompt), whether browser or installed app, and a screenshot of the built-in diagnostic panel at bass.omrihefez.com/?debug — that panel exists precisely for this and will name the failure directly.

Filed rather than left as an answered message because he reported a fault and asked for a fix, and it is NOT fixed. If his two taps resolve it, close this with what it was — that answer is worth keeping, since "the tuner stopped working" has now happened once and will happen again.

## Log
- 2026-08-15 CODE READ, so his answer converts straight into a fix rather than starting an investigation.

tuner.js already self-diagnoses and writes the fault to $micStatus in red. The branches, from the .catch on getUserMedia (~line 542):

  NotAllowedError / "denied"  -> "Mic permission denied…" and the message itself spells out the Chrome path
  NotFoundError               -> "No microphone found on this device."
  location.protocol != https  -> "Mic only works over HTTPS."
  anything else               -> generic "Mic error: <message>"

THE GAP WORTH KNOWING: NotReadableError has NO dedicated branch, so "microphone is held by another app or a backgrounded instance of us" falls into the generic bucket and reads as an opaque "Mic error: Could not start audio source". That is precisely the leaked-stream case bt-8e75 addressed in code, and it is the one a user cannot self-diagnose from the text. If his screenshot shows that shape, the fix is swiping the app from recents — and this branch deserves its own message saying so.

DISCRIMINATOR I gave him, which is sharper than the debug panel:
  red text present  -> the text names the fault and usually the fix
  "Listening…" in normal text but a dead needle -> mic opened fine, problem is downstream in pitch detection, want the ?debug panel for that
  blank page -> not a mic problem at all

Also relevant to the "held mic" theory: stop() does correctly release — it stops every track, closes the AudioContext and nulls the refs. So a clean Stop frees the device; only a backgrounded/crashed instance would hold it.

Told him it can wait until morning: server, deploy and code are all verified healthy, so nothing degrades while it sits.
- 2026-08-26 blocker bt-8e75 closed 2026-07-21T21:45:27Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-5fb7 closed 2026-08-05T06:21:13Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-8e75 closed 2026-07-21T21:45:27Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-5fb7 closed 2026-08-05T06:21:13Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-8e75 closed 2026-07-21T21:45:27Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-5fb7 closed 2026-08-05T06:21:13Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-8e75 closed 2026-07-21T21:45:27Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-5fb7 closed 2026-08-05T06:21:13Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-8e75 closed 2026-07-21T21:45:27Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-5fb7 closed 2026-08-05T06:21:13Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-8e75 closed 2026-07-21T21:45:27Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-5fb7 closed 2026-08-05T06:21:13Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-8e75 closed 2026-07-21T21:45:27Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-5fb7 closed 2026-08-05T06:21:13Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-8e75 closed 2026-07-21T21:45:27Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-5fb7 closed 2026-08-05T06:21:13Z — recheck whether this can proceed now.
