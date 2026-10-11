// Locking a string must narrow what the DETECTOR may return, not just which
// target the reading is compared against.
//
// Omri, 2026-10-11 22:49, tuning drop D: "I play the g on the bass and it shows
// much lower freqs. Keep jumping even when I lock the g."
//
// Cause: state.selectedString fed only the `idx` pick in the display path.
// freqRange() derived its window from every note in the tuning, so a locked G2
// (98 Hz) still allowed YIN to return anything in ~[31,131] Hz for drop D —
// including 49 Hz, exactly half of 98 and a whisker from 50 Hz amp hum. The
// reading flipped between the two and the needle slammed to -1200 cents.
//
// NOTE ON COVERAGE: mains-hum.test.js's "every string detects under amp hum, in
// every tuning" never sets state.selectedString, so it only ever exercised
// AUTO-detect. The locked path had no test at all, which is why this shipped.
const { test } = require("node:test");
const assert = require("node:assert/strict");
const { loadTuner } = require("./harness.js");

const T = loadTuner();
const { midiToFreq, freqRange, state, INSTRUMENTS } = T;

function withBass(tuningKey, selectedString, fn) {
  const prev = { i: state.instrumentKey, t: state.tuningKey, s: state.selectedString };
  state.instrumentKey = "bass";
  state.tuningKey = tuningKey;
  state.selectedString = selectedString;
  try { return fn(); } finally {
    state.instrumentKey = prev.i; state.tuningKey = prev.t; state.selectedString = prev.s;
  }
}

test("drop D, locked G: the half-frequency is OUT of the search window", () => {
  const g2 = midiToFreq(INSTRUMENTS.bass.tunings.dropD.notes[3], state.aref);
  withBass("dropD", 3, () => {
    const { minFreq, maxFreq } = freqRange();
    assert.ok(g2 >= minFreq && g2 <= maxFreq,
      `G2 ${g2.toFixed(2)} must be inside [${minFreq.toFixed(2)},${maxFreq.toFixed(2)}]`);
    assert.ok(g2 / 2 < minFreq,
      `the half-frequency ${(g2 / 2).toFixed(2)} must be BELOW minFreq ${minFreq.toFixed(2)} — this is the bug`);
    assert.ok(g2 * 2 > maxFreq,
      `the double ${(g2 * 2).toFixed(2)} must be ABOVE maxFreq ${maxFreq.toFixed(2)}`);
    assert.ok(50 < minFreq, `50 Hz mains hum must be below minFreq ${minFreq.toFixed(2)}`);
  });
});

test("every bass string, every tuning: locked window excludes its own half and double", () => {
  for (const [key, tuning] of Object.entries(INSTRUMENTS.bass.tunings)) {
    tuning.notes.forEach((midi, i) => {
      withBass(key, i, () => {
        const f = midiToFreq(midi, state.aref);
        const { minFreq, maxFreq } = freqRange();
        assert.ok(f >= minFreq && f <= maxFreq, `${key}[${i}] ${f.toFixed(2)} outside its own window`);
        assert.ok(f / 2 < minFreq, `${key}[${i}]: half ${(f / 2).toFixed(2)} inside window [${minFreq.toFixed(2)},${maxFreq.toFixed(2)}]`);
        assert.ok(f * 2 > maxFreq, `${key}[${i}]: double ${(f * 2).toFixed(2)} inside window`);
      });
    });
  }
});

test("locked window still tolerates a string mid-retune (E down to D, and slacker)", () => {
  // He locks the low string and slackens E1 -> D1: two semitones. The window must
  // not refuse to read it on the way, or the lock is useless for the one job it has.
  withBass("dropD", 0, () => {
    const { minFreq, maxFreq } = freqRange();
    const d1 = midiToFreq(26, state.aref), e1 = midiToFreq(28, state.aref);
    assert.ok(e1 <= maxFreq, `E1 ${e1.toFixed(2)} must still read while locked to D1 (max ${maxFreq.toFixed(2)})`);
    assert.ok(d1 >= minFreq, `D1 ${d1.toFixed(2)} must read (min ${minFreq.toFixed(2)})`);
    // four semitones slack below target still reads
    assert.ok(midiToFreq(22, state.aref) >= minFreq, "4 semitones slack below D1 must still read");
  });
});

test("UNLOCKED auto-detect range is unchanged — regression guard", () => {
  withBass("dropD", null, () => {
    const { minFreq, maxFreq } = freqRange();
    const notes = INSTRUMENTS.bass.tunings.dropD.notes;
    assert.equal(minFreq.toFixed(4), Math.max(25, midiToFreq(Math.min(...notes) - 3, state.aref)).toFixed(4));
    assert.equal(maxFreq.toFixed(4), midiToFreq(Math.max(...notes) + 5, state.aref).toFixed(4));
    // every string must be reachable in auto mode, which is the whole point of auto
    for (const m of notes) {
      const f = midiToFreq(m, state.aref);
      assert.ok(f >= minFreq && f <= maxFreq, `auto: ${f.toFixed(2)} must be in range`);
    }
  });
});

test("an out-of-range selectedString falls back to the whole-tuning window", () => {
  withBass("dropD", 99, () => {
    const { minFreq, maxFreq } = freqRange();
    const notes = INSTRUMENTS.bass.tunings.dropD.notes;
    assert.equal(maxFreq.toFixed(4), midiToFreq(Math.max(...notes) + 5, state.aref).toFixed(4));
  });
});
