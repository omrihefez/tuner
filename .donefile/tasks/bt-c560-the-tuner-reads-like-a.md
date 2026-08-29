---
id: bt-c560
title: The tuner reads like a number display, not a tuner — needs a needle that moves with you,
  flat-left sharp-right, obvious in-tune state
status: open
priority: p1
tags:
  - from-omri
  - ui
created: 2026-08-29
---

HIS WORDS (voice, 2026-08-29 17:15): "when you're tuning, you play again and again and again and you
expect to see the bar moving. The bar — the app is ugly, super ugly. There's no bar, like the number
appears and then it stops. You can find on the internet all the tuners, they have better indications
for the users, up and down, it's moving with you... right now it's just unusable. Time to step it up."

And earlier, which is the standard he is holding this to: "this app should be perfect. The algorithms
and the physics are out there... the only reason we build it is because the apps that already built
it are behind paywalls for down tunings. But if I can't use it to tune, it just doesn't work in the
real world."

THE DETECTION HALF IS DONE AND SHIPPED — do not redo it:
  - 6a95acf: 50 Hz mains-hum rejection (least-squares partial subtraction).
  - 25918d8: keeps detecting as a note decays. RMS floor lowered to match the post-subtraction
    signal level, plus a YIN fallback that takes the best candidate below 0.35 when nothing clears
    the strict 0.12 threshold. Silence and white noise still return -1, tested.
  - Measured: Eb1 under amp hum now tracks down to amplitude 0.005 (previously stopped); three
    successive decaying plucks detect on 36/36 frames.
  - Live and verified, build marker 0829-1721.

WHAT IS STILL OPEN — the indicator itself. Note that index.html ALREADY HAS a needle
(.needle-track / .needle-bar / #needle / #cents-display), so "there's no bar" means it does not read
as one, or was not moving because detection was dropping out. Now that detection is continuous, the
visuals are the remaining half and they are his actual complaint.

DONE WHEN he can tune by watching it, not by reading a number:
  - The needle moves CONTINUOUSLY while a string rings, easing every animation frame rather than
    stepping when a new reading lands.
  - Unmistakable direction: flat = left, sharp = right, with the target dead centre. He should not
    have to interpret a signed number to know which way to turn the peg.
  - A clear in-tune state — a green zone and something that changes decisively when he arrives,
    readable at arm's length while both hands are on the instrument.
  - The note name large and obvious; cents secondary.
  - Look at what real tuners do. He explicitly said other apps do this better and that the only
    reason this one exists is that they paywall down-tunings.

CONSTRAINTS: light theme (his standing preference). Screen-reader announcements already exist via
#tuner-announcer — keep them working. Test at 390x844 and across 360-430 widths. style.css is
CACHE-FIRST in sw.js, so any CSS change needs the CACHE version bumped or it never reaches his
phone — the repo's check-sw-cache-bump gate enforces this on push and it caught me today.

VERIFY: deploy and confirm live by hashing the served files against the repo, and check the build
marker changes. Merged is not shipped, and he judged an earlier fix while his phone was still
running old code.
