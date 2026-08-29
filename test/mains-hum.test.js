// Mains-hum rejection. Omri, 2026-08-29: "I can't tune a drop 1/2 tone. It does
// not detect the notes properly... It was working okay. Now it's gotten worse."
//
// Nothing in the code had changed. What changed was his signal path: playing
// through an amp puts 50 Hz mains hum into the mic, and hum is far more periodic
// than a decaying plucked string, so YIN locks onto it. Half-step down suffers
// most — its notes sit nearer 50 Hz and its search window opens lower.
//
// These are the exact scenarios that failed before rejectMainsHum existed.
const { test } = require("node:test");
const assert = require("node:assert/strict");
const { loadTuner } = require("./harness.js");

const T = loadTuner();
const { midiToFreq, detectPitchYIN, rejectMainsHum, freqRange, state, INSTRUMENTS } = T;
const SR = 22050, SIZE = 8192;

// A plucked string with a weak fundamental, optionally buried in amp hum.
function signal(f0, { hum = 0, noise = 0, decay = false } = {}) {
  const b = new Float32Array(SIZE);
  const parts = [[1, 0.3], [2, 1.0], [3, 0.7], [4, 0.4], [5, 0.25]];
  for (let i = 0; i < SIZE; i++) {
    let v = 0;
    for (const [h, a] of parts) v += a * Math.sin(2 * Math.PI * f0 * h * i / SR);
    if (decay) v *= Math.exp(-2.2 * i / SR);
    if (hum) v += hum * (Math.sin(2 * Math.PI * 50 * i / SR)
                       + 0.5 * Math.sin(2 * Math.PI * 100 * i / SR)
                       + 0.3 * Math.sin(2 * Math.PI * 150 * i / SR));
    if (noise) v += noise * (Math.random() * 2 - 1);
    b[i] = v * 0.15;
  }
  return b;
}

function rms(a) { let s = 0; for (let i = 0; i < a.length; i++) s += a[i] * a[i]; return Math.sqrt(s / a.length); }
function tone(f) { const b = new Float32Array(SIZE); for (let i = 0; i < SIZE; i++) b[i] = Math.sin(2 * Math.PI * f * i / SR); return b; }

test("the hum fundamental is removed", () => {
  const before = rms(tone(50));
  const after = rms(rejectMainsHum(tone(50), SR, 50));
  assert.ok(after / before < 0.01, `50 Hz should be gone, got ${(20 * Math.log10(after / before)).toFixed(1)} dB`);
});

// The constraint that rules out both a high-pass and a wide notch: these are real
// strings, one of them 1.9 Hz from the hum and one BELOW it.
test("strings next to the hum survive", () => {
  for (const f of [38.89, 41.20, 51.91, 92.50]) {
    const before = rms(tone(f));
    const after = rms(rejectMainsHum(tone(f), SR, 50));
    const db = 20 * Math.log10(after / before);
    assert.ok(db > -2, `${f} Hz should pass through, lost ${db.toFixed(1)} dB`);
  }
});

test("every string detects under amp hum, in every tuning", () => {
  for (const opts of [{ hum: 0.3 }, { hum: 0.8 }, { hum: 0.6, noise: 0.1, decay: true }]) {
    for (const tuningKey of Object.keys(INSTRUMENTS.bass.tunings)) {
      state.instrumentKey = "bass";
      state.tuningKey = tuningKey;
      const { minFreq, maxFreq } = freqRange();
      for (const midi of INSTRUMENTS.bass.tunings[tuningKey].notes) {
        const f0 = midiToFreq(midi, state.aref);
        const clean = rejectMainsHum(signal(f0, opts), SR, state.mainsHz);
        const got = detectPitchYIN(clean, SR, minFreq, maxFreq);
        assert.ok(got > 0, `${tuningKey} midi ${midi}: no detection under ${JSON.stringify(opts)}`);
        const cents = 1200 * Math.log2(got / f0);
        assert.ok(Math.abs(cents) < 25,
          `${tuningKey} midi ${midi}: got ${got.toFixed(1)}Hz, ${cents.toFixed(0)} cents off under ${JSON.stringify(opts)}`);
      }
    }
  }
});
