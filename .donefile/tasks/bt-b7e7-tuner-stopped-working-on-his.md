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
- 2026-09-04 PARTIAL FIX SHIPPED AND LIVE by Main, 2026-09-04 ~04:55 IDT — commit 99c1ba9 on main, verified live at bass.omrihefez.com (tuner.js serves the new branch, sw.js reads tuner-v14, page 200 in 0.22s). This does NOT close the task: it does not establish what broke on his device on 2026-08-15, and I still do not know. What changed is that the NEXT occurrence explains itself. Two branches were wrong. (1) NotReadableError had no branch, so 'the mic is held by another app or by a backgrounded copy of us' — the leaked-stream shape bt-8e75 addressed in code, and candidate 3 in this task's own list — rendered as the opaque 'Mic error: Could not start audio source'. It now names the cause and the fix (close the other app, or swipe this one from recents). TrackStartError, Chrome's older alias for the same condition, maps to the same branch. (2) The HTTPS branch was UNREACHABLE: an insecure origin rejects with NotAllowedError, which matched first, so a protocol problem sent the user to a Chrome site-settings page that cannot fix it. The protocol check now runs first. Six tests written BEFORE the fix: 3 failed and 3 passed against the old code, and the 3 passes are load-bearing — they prove the harness reaches the real #mic-status element rather than a fresh stand-in that would make every assertion vacuous. 117/117 repo tests green. WHY I DID THIS RATHER THAN CHASE HIM AGAIN: the task was filed 2026-08-15 and has been parked 20 days on a screenshot that never arrived, which is a dark route, not a blocked one — and its own body already identified this branch as 'the one a user cannot self-diagnose'. STILL OPEN: whether his device is working today. He has not mentioned the tuner since 08-15 and I have not asked again; that question is worth one line next time he is in the app, not another 20-day wait.
- 2026-09-28 2026-09-28 04:26 — WHY THIS SITS OPEN AND UNCLAIMED, so the next sweep does not read it as neglect. It surfaced in omri-request-sweep's NEVER_CLAIMED list tonight (from-omri, p1, created 2026-08-15, 44 days, on a DISPATCHABLE board), which looks exactly like a buried request of his. I checked before treating it as one: it is not.

The 2026-09-04 pass shipped a partial fix LIVE (99c1ba9, verified at bass.omrihefez.com: tuner.js serving the new branch, sw.js reading tuner-v14) with six tests written BEFORE the fix — 3 failing and 3 passing, the passes load-bearing because they prove the harness reaches the real #mic-status element instead of a stand-in that would make every assertion vacuous. 117/117 repo tests green. That pass also reasoned correctly about not waiting: 20 days on a screenshot that never arrived is a dark route, not a blocked one.

WHAT ACTUALLY REMAINS is one question, quoted from that note: 'whether his device is working today ... worth one line next time he is in the app, not another 20-day wait.' That is why it is in the ready pool yet unclaimed — a worker that claimed it would have nothing to do. The remaining step is a sentence to Omri, not code.

ACTIONABLE, and the reason I am writing rather than just noting: he lands 2026-09-30 06:50 (LY82, per trips-hub's typed itinerary — NOT 09-29, which is the departure day and the off-by-one ce-3ae9 fixed in the engine's away-dial). The next time he is in the app, ask one line: is the tuner working on your phone now? If yes, close this on his answer. If no, the 2026-09-04 fix means the NEXT failure names its own cause — NotReadableError/TrackStartError now say 'another app holds the mic' and the protocol check runs before the permissions branch — so his answer will be diagnostic rather than another round of guessing.

NOT raising this on his Needs-you screen: it is a question to slip into conversation, not a declared ask, and padding that screen with things he did not ask to decide is what cost it credibility on 2026-08-07. Also, Main currently cannot POST a needs-you row with its own bearer at all (ma-a43c).
- 2026-09-28 blocker ma-a43c closed 2026-09-28T07:06:04Z — recheck whether this can proceed now.
- 2026-10-06 Main 2026-10-06 14:1x — PROVENANCE WARNING on this task's own 2026-09-28 note, before anyone acts on it.

That note says he 'has been back since 2026-09-30'. A discovery worker surfaced that line to me today, then corrected its own provenance unprompted: the claim was not an observation, it was derived from trips-hub's TYPED ITINERARY (LY82, landing 06:50). A scheduled arrival is not evidence he landed, and certainly not that he opened the app. Do not treat it as a measurement.

THE SEPARATE, REAL MEASUREMENT, which happens to point the same way: scoped to his own thread (session_id='main'), last read 2026-10-06 13:21, 5 unread of 3799. He is reading the app and keeping up. So he IS reachable and this task's remaining step — one sentence asking whether the tuner works on his phone now — is actually askable, which it would not have been if the itinerary line had been the only basis.

WHY THE DISTINCTION MATTERS HERE RATHER THAN BEING PEDANTRY: this task has sat open since 2026-08-15 waiting on exactly one question. If someone had closed or escalated it off the itinerary row and he had not in fact been back, the question would have gone into a void and the task would have looked answered. The two facts agreeing is luck, not corroboration.

NEXT STEP IS MINE: ask him the one line, in his thread, and close this on his answer. Not asking now — it is 14:1x on a Tuesday, inside the 9-18 window, and a 'does your tuner work' question does not justify interrupting a workday. It goes with the next thing that genuinely needs him, or after 18:00.
