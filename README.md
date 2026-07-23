# Tuner

A free, open-source, ad-free chromatic tuner for bass and guitar. Runs in any modern browser. Installable as a PWA.

Live at **[tuner.omrihefez.com](https://tuner.omrihefez.com)**.

## Features

- **Bass** (4 & 5 string) — Standard, Drop D, Drop C, ½ step down
- **Guitar** (6 & 7 string) — Standard, Drop D, DADGAD, Open G, ½ step down
- **Adjustable reference frequency** — A₄ slider 415–466 Hz with 1-tap presets (431, 432, 440, 441) for Radiohead-style alternative tunings
- **YIN pitch detection** — handles bass harmonic-heavy spectra without octave-locking onto the wrong fundamental
- **Auto-detect or lock** — play any string and the tuner picks the closest, or tap a string to pin
- **Mobile-first PWA** — installs to your home screen, works offline after first load
- **Zero tracking** — no analytics, no ads, no accounts, no data leaves your device

## How it works

The mic captures audio via the Web Audio API, resampled to 22.05kHz. Each frame, an 8192-sample window (~370ms) is fed to a YIN pitch detector (de Cheveigné & Kawahara, 2002): cumulative mean normalized difference function → absolute threshold → parabolic interpolation. Detected frequencies pass through a median-of-6 smoothing filter to reject octave jumps. The needle shows cents off the nearest string in the current tuning, scaled relative to your A₄ reference.

All of this happens client-side. The server only ships static HTML/CSS/JS.

## Run locally

```bash
git clone https://github.com/omrihefez/tuner.git
cd tuner
# Any static file server works
python3 -m http.server 8000
# Then open http://localhost:8000 — note that getUserMedia requires either HTTPS
# or localhost, so file:// won't work.
```

## Tests

The pitch math (`midiToFreq`, `freqToMidi`, `noteLabel`, cents, `closestString`,
`freqRange`, `medianPitch`, and the YIN detector) has known-answer tests. They run
the **real `tuner.js`** inside a `vm` sandbox with a stub DOM — no re-implementation,
no build step, no dependencies (uses the Node ≥18 built-in test runner).

```bash
npm test        # == node --test test/*.test.js
```

- `test/harness.js` — evaluates `tuner.js` in a sandbox and hands back its pure functions.
- `test/pitch-math.test.js` — the known-answer cases (equal-temperament values, etc.).

## Deploy

Push to Vercel (or any static host). The `vercel.json` config is minimal: just a no-cache rule for the service worker.

## License

MIT. See `LICENSE`.

## Built by

[Meni](https://github.com/omrihefez/meni) — an experiment by [Omri Hefez](https://omrihefez.com).
