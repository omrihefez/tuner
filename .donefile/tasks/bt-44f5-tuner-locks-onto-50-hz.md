---
id: bt-44f5
title: Tuner locks onto 50 Hz amp hum instead of the string — half-step down worst hit, G#1 reads
  'in tune' while measuring the amplifier
status: open
priority: p1
tags:
  - from-omri
  - audio
created: 2026-08-29
---

HIS WORDS (2026-08-29 16:47): "I don't know what you did to tuner app but it have gotten worse. I
can't tune a drop 1/2 tone. It does not detect the notes properly. Work on it now please. I wanna
play."

And the voice note two minutes later, which reframed the whole task: "this app should be perfect...
the algorithms and the physics are out there, no reason for it not to be perfect. The only reason we
build it is because the apps that already built it are behind paywalls for down tunings. But if I
can't use it to tune, it just don't work in the real world. Of course a note is not clean, and I play
a bass guitar, and the amplifier, and there are several tones."

He is right on the framing: a tuner that works on clean signals and fails on a real bass through a
real amp is not a working tuner.

ROOT CAUSE: 50 Hz mains hum. An electric bass through an amp feeds the mains fundamental and its
low harmonics into the mic. Hum is far more PERIODIC than a decaying plucked string, so YIN prefers
it. Nothing in the code had changed — his signal path had, which is exactly why "it was working
okay, now it's gotten worse" was both true and baffling.

Reproduced before fixing, on synthetic signals with realistic amp hum:
  standard   E1 FAIL   A1 FAIL   D2 FAIL   G2 -> 49.0 Hz (an octave out)
  half-step  D#1 FAIL  G#1 "ok"  C#2 FAIL  F#2 -> 46.3 Hz
G#1 reading "ok" is the worst of it: 51.9 Hz is a whisker from 50 Hz, so the tuner sat there looking
confident and in tune while measuring the amplifier. Half-step suffers more than standard, exactly as
he reported — its notes sit nearer the hum and its search window opens lower, so more of the hum's
harmonic series falls inside the range YIN may pick from.

TWO APPROACHES MEASURED AND REJECTED, recorded so nobody re-treads them:
1. High-pass — unusable. The lowest half-step string is Eb1 at 38.89 Hz, BELOW the hum. Anything
   steep enough to remove 50 Hz removes the note.
2. IIR notch — tried first and it FAILED. A notch narrow enough to spare G#1 (Q=30, ~1.7 Hz) needs
   ~1.5s to settle; the analyser window is 8192 samples at 22.05kHz = 0.37s. Measured: -0.9 dB of
   rejection at 50 Hz while costing G#1 -1.5 dB — it attenuated the string MORE than the hum.
   Priming by repeating the window does not rescue it: 50 Hz is not a whole number of cycles in 8192
   samples, so every repeat seam is a discontinuity that re-excites the transient. Measured Q/prime
   combinations before abandoning it.

WHAT SHIPPED: least-squares removal of each hum partial — project the window onto sin/cos at
50/100/150 Hz and subtract exactly that component. No filter state, therefore no transient and no
settling time. The 2x2 normal equations are solved rather than assuming cos/sin orthogonality; over
a window that is not a whole number of cycles they are not orthogonal, and assuming so leaves a
residual exactly where it hurts.

MEASURED AFTER: 50 Hz -154 dB. Eb1 and E1 lose 0.0 dB, G#1 loses 0.6 dB, F#2 0.0 dB. Every string in
standard, half-step, drop D and drop C# detects within 25 cents under quiet hum, loud hum, and
hum+noise+decay.

Commit 6a95acf, test/mains-hum.test.js (3 cases incl. the two constraints that rule out the rejected
approaches). Suite 109 pass / 0 fail. Deployed and verified live: bass.omrihefez.com/tuner.js now
hashes identical to the repo and contains the fix.

STILL OPEN AS A QUESTION FOR HIM: whether it now works on his actual instrument. Synthetic hum is a
model, not his amp. Offered to model his exact signal if he records a few seconds of a note.

Two incidental blockers fixed on the way out, both real: the pre-push gate refused every push from
this repo because it has ZERO dependencies so node_modules can never exist (a regression from
dn-14b1, which changed silent-skip to refuse); and vercel.json declared no outputDirectory, so the
deploy failed looking for public/.
