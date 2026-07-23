// Known-answer tests for the bass-tuner pitch math.
//
// Every value below is an independently-derived expected result (equal-temperament
// formulas, hand-computed), not a snapshot of whatever the code currently returns.
// Run with:  npm test   (== node --test test/)

const { test } = require("node:test");
const assert = require("node:assert/strict");
const { loadTuner } = require("./harness.js");

const T = loadTuner();
const {
  midiToFreq, freqToMidi, noteLabel, closestString,
  medianPitch, detectPitchYIN, freqRange, currentTuning, state,
  INSTRUMENTS,
} = T;

// Float comparison with an absolute tolerance.
function approx(actual, expected, tol, msg) {
  assert.ok(
    Math.abs(actual - expected) <= tol,
    `${msg || ""} expected ~${expected} (±${tol}), got ${actual}`,
  );
}

// Reset tuner state to a known instrument/tuning/A-ref before a group that reads it.
function setTuning(instrumentKey, tuningKey, aref = 440) {
  state.instrumentKey = instrumentKey;
  state.tuningKey = tuningKey;
  state.aref = aref;
  state.selectedString = null;
}

// -----------------------------------------------------------------------------
// midiToFreq — MIDI note number → frequency (equal temperament, f = a·2^((m-69)/12))
// -----------------------------------------------------------------------------
test("midiToFreq: concert A (A4, midi 69) is the reference A-ref", () => {
  assert.equal(midiToFreq(69, 440), 440);
  assert.equal(midiToFreq(69, 432), 432);
});

test("midiToFreq: octaves double / halve the frequency", () => {
  approx(midiToFreq(57, 440), 220, 1e-9, "A3");   // one octave below A4
  approx(midiToFreq(81, 440), 880, 1e-9, "A5");   // one octave above A4
});

test("midiToFreq: standard string fundamentals @ A=440", () => {
  approx(midiToFreq(45, 440), 110.0, 1e-6, "A2");                 // guitar A / bass A1 octave up
  approx(midiToFreq(40, 440), 82.4068892282, 1e-6, "E2 (guitar low E)");
  approx(midiToFreq(28, 440), 41.2034446141, 1e-6, "E1 (bass low E, 4-string)");
  approx(midiToFreq(23, 440), 30.8677063285, 1e-6, "B0 (5-string bass low B)");
  approx(midiToFreq(64, 440), 329.6275569129, 1e-6, "E4 (guitar high E)");
});

test("midiToFreq: A-ref shift scales every note proportionally", () => {
  // At A=432 every note is 432/440 of its 440 value.
  approx(midiToFreq(40, 432), 82.4068892282 * 432 / 440, 1e-6, "E2 @432");
});

// -----------------------------------------------------------------------------
// freqToMidi — inverse of midiToFreq
// -----------------------------------------------------------------------------
test("freqToMidi: reference and octaves land on exact integers", () => {
  approx(freqToMidi(440, 440), 69, 1e-9, "A4");
  approx(freqToMidi(110, 440), 45, 1e-9, "A2");
  approx(freqToMidi(220, 440), 57, 1e-9, "A3");
  approx(freqToMidi(880, 440), 81, 1e-9, "A5");
});

test("freqToMidi ∘ midiToFreq round-trips for every MIDI note in range", () => {
  for (let m = 0; m <= 127; m++) {
    for (const aref of [432, 440, 442]) {
      approx(freqToMidi(midiToFreq(m, aref), aref), m, 1e-9, `midi ${m} @${aref}`);
    }
  }
});

test("freqToMidi: a half step up is +1.0, a whole step is +2.0", () => {
  approx(freqToMidi(midiToFreq(46, 440), 440) - 45, 1, 1e-9, "semitone");
  approx(freqToMidi(midiToFreq(47, 440), 440) - 45, 2, 1e-9, "whole tone");
});

// -----------------------------------------------------------------------------
// cents deviation — the readout is (freqToMidi(freq) - targetMidi) * 100
// -----------------------------------------------------------------------------
function centsOff(freq, targetMidi, aref) {
  return (freqToMidi(freq, aref) - targetMidi) * 100;
}

test("cents: dead-on target reads 0 cents", () => {
  approx(centsOff(midiToFreq(45, 440), 45, 440), 0, 1e-9, "A2 on pitch");
});

test("cents: one semitone sharp reads +100, one flat reads -100", () => {
  approx(centsOff(midiToFreq(46, 440), 45, 440), 100, 1e-9, "semitone sharp");
  approx(centsOff(midiToFreq(44, 440), 45, 440), -100, 1e-9, "semitone flat");
});

test("cents: +50 cents is a quarter-tone above target", () => {
  const target = 45;
  const freq = midiToFreq(target, 440) * Math.pow(2, 50 / 1200);
  approx(centsOff(freq, target, 440), 50, 1e-6, "quarter tone sharp");
});

// -----------------------------------------------------------------------------
// noteLabel — MIDI note number → note name + octave (rounds to nearest note)
// -----------------------------------------------------------------------------
test("noteLabel: reference notes name correctly (scientific pitch notation)", () => {
  assert.equal(noteLabel(69), "A4");
  assert.equal(noteLabel(60), "C4");   // middle C
  assert.equal(noteLabel(40), "E2");
  assert.equal(noteLabel(28), "E1");
  assert.equal(noteLabel(23), "B0");
  assert.equal(noteLabel(45), "A2");
});

test("noteLabel: sharps use the ♯ glyph", () => {
  assert.equal(noteLabel(61), "C♯4");
  assert.equal(noteLabel(70), "A♯4");
  assert.equal(noteLabel(34), "A♯1");
});

test("noteLabel: extreme MIDI range", () => {
  assert.equal(noteLabel(0), "C-1");   // lowest MIDI note
  assert.equal(noteLabel(12), "C0");
  assert.equal(noteLabel(127), "G9");  // highest MIDI note
});

test("noteLabel: rounds a fractional MIDI value to the nearest note", () => {
  assert.equal(noteLabel(68.6), "A4");
  assert.equal(noteLabel(69.4), "A4");
});

// -----------------------------------------------------------------------------
// medianPitch — median of recent samples (upper-middle element on even counts)
// -----------------------------------------------------------------------------
test("medianPitch: empty input returns the -1 sentinel", () => {
  assert.equal(medianPitch([]), -1);
});

test("medianPitch: single sample returns itself", () => {
  assert.equal(medianPitch([82.4]), 82.4);
});

test("medianPitch: odd count returns the middle of the sorted values", () => {
  assert.equal(medianPitch([3, 1, 2]), 2);
  assert.equal(medianPitch([5, 3, 1, 4, 2]), 3);
});

test("medianPitch: even count returns the upper-middle sorted value", () => {
  // sorted = [1,2,3,4]; index floor(4/2)=2 -> 3
  assert.equal(medianPitch([4, 2, 3, 1]), 3);
});

test("medianPitch: rejects a spurious octave-double outlier", () => {
  // Four good ~110 Hz reads plus one doubled 220 Hz glitch -> median stays ~110.
  assert.equal(medianPitch([110.1, 109.8, 220.0, 110.0, 109.9]), 110.0);
});

// -----------------------------------------------------------------------------
// closestString — index of the nearest string (log-scale) in the current tuning
// -----------------------------------------------------------------------------
test("closestString: bass standard (E1 A1 D2 G2) maps fundamentals to their string", () => {
  setTuning("bass", "standard");
  // Copy out of the vm realm before comparing (cross-realm prototypes differ).
  assert.deepEqual(Array.from(currentTuning().notes), [28, 33, 38, 43]);
  assert.equal(closestString(midiToFreq(28, 440)), 0, "E1");
  assert.equal(closestString(midiToFreq(33, 440)), 1, "A1");
  assert.equal(closestString(midiToFreq(38, 440)), 2, "D2");
  assert.equal(closestString(midiToFreq(43, 440)), 3, "G2");
});

test("closestString: picks the nearer of two strings for an off-pitch input", () => {
  setTuning("bass", "standard");
  // A hair sharp of D2 (73.4 Hz) is still closest to the D string (index 2).
  assert.equal(closestString(75), 2);
  // Just above A1 (55 Hz) but far below D2 -> A string (index 1).
  assert.equal(closestString(58), 1);
});

test("closestString: guitar standard (E2..E4) maps the outer strings", () => {
  setTuning("guitar", "standard");
  assert.deepEqual(Array.from(currentTuning().notes), [40, 45, 50, 55, 59, 64]);
  assert.equal(closestString(midiToFreq(40, 440)), 0, "low E2");
  assert.equal(closestString(midiToFreq(64, 440)), 5, "high E4");
});

// -----------------------------------------------------------------------------
// freqRange — detection window derived from the current tuning (+ A-ref)
// -----------------------------------------------------------------------------
test("freqRange: brackets the strings and excludes the G string's 2nd harmonic", () => {
  setTuning("bass", "standard");             // E1..G2, fundamentals 41.2..98.0 Hz
  const { minFreq, maxFreq } = freqRange();
  // Lowest string (E1, 41.2 Hz) sits inside the window...
  assert.ok(minFreq < midiToFreq(28, 440), `minFreq ${minFreq} should be below E1`);
  // ...highest string (G2, 98.0 Hz) inside...
  assert.ok(maxFreq > midiToFreq(43, 440), `maxFreq ${maxFreq} should be above G2`);
  // ...but G2's 2nd harmonic (~196 Hz) is excluded, which is what prevents the
  // octave-up lock bug on the D/G strings.
  assert.ok(maxFreq < 196, `maxFreq ${maxFreq} must exclude the 196 Hz harmonic`);
});

test("freqRange: never opens the low edge below the 25 Hz floor", () => {
  setTuning("bass", "fiveString");           // includes B0 (30.9 Hz)
  const { minFreq } = freqRange();
  assert.ok(minFreq >= 25, `minFreq ${minFreq} must respect the 25 Hz floor`);
});

// -----------------------------------------------------------------------------
// closestString / freqRange — every instrument+tuning preset, not just the two
// spot-checked above. Walks the actual INSTRUMENTS table (copied out of the vm
// realm first) so a newly added preset is covered automatically.
// -----------------------------------------------------------------------------
const ALL_PRESETS = [];
for (const [instrumentKey, inst] of Object.entries(INSTRUMENTS)) {
  for (const tuningKey of Object.keys(inst.tunings)) {
    ALL_PRESETS.push({
      instrumentKey,
      tuningKey,
      label: `${inst.name} / ${inst.tunings[tuningKey].name}`,
      notes: Array.from(inst.tunings[tuningKey].notes),
    });
  }
}

// Sanity check on the fixture itself: bass has 6 tunings, guitar has 6 tunings.
test("preset fixture: covers every instrument x tuning combination", () => {
  assert.equal(ALL_PRESETS.length, 12, "expected 6 bass + 6 guitar presets");
});

for (const preset of ALL_PRESETS) {
  test(`closestString: ${preset.label} maps every string's own fundamental back to itself`, () => {
    setTuning(preset.instrumentKey, preset.tuningKey);
    preset.notes.forEach((midi, i) => {
      const freq = midiToFreq(midi, 440);
      assert.equal(
        closestString(freq), i,
        `${preset.label}: string ${i} (midi ${midi}, ${freq.toFixed(2)} Hz) should resolve to itself`,
      );
    });
  });

  test(`freqRange: ${preset.label} window brackets every string and respects the 25 Hz floor`, () => {
    setTuning(preset.instrumentKey, preset.tuningKey);
    const { minFreq, maxFreq } = freqRange();
    assert.ok(minFreq >= 25, `${preset.label}: minFreq ${minFreq} must respect the 25 Hz floor`);
    assert.ok(minFreq < maxFreq, `${preset.label}: minFreq ${minFreq} must be below maxFreq ${maxFreq}`);
    const lo = Math.min(...preset.notes), hi = Math.max(...preset.notes);
    assert.ok(
      minFreq <= midiToFreq(lo, 440),
      `${preset.label}: minFreq ${minFreq} should be at or below the lowest string (${midiToFreq(lo, 440).toFixed(2)} Hz)`,
    );
    assert.ok(
      maxFreq >= midiToFreq(hi, 440),
      `${preset.label}: maxFreq ${maxFreq} should be at or above the highest string (${midiToFreq(hi, 440).toFixed(2)} Hz)`,
    );
  });
}

// -----------------------------------------------------------------------------
// detectPitchYIN — end-to-end on a synthesised tone (integration known-answer)
// -----------------------------------------------------------------------------
function sineBuffer(freqHz, sampleRate, length, amp = 0.5) {
  const buf = new Float32Array(length);
  for (let i = 0; i < length; i++) {
    buf[i] = amp * Math.sin((2 * Math.PI * freqHz * i) / sampleRate);
  }
  return buf;
}

test("detectPitchYIN: recovers the fundamental of a clean sine within 0.5 Hz", () => {
  const sampleRate = 44100;
  for (const f of [41.2, 55.0, 82.41, 110.0, 146.83]) {
    const buf = sineBuffer(f, sampleRate, 8192);
    const detected = detectPitchYIN(buf, sampleRate, 25, 400);
    approx(detected, f, 0.5, `sine ${f} Hz`);
  }
});

test("detectPitchYIN: gates out silence / sub-threshold noise, returning -1", () => {
  const sampleRate = 44100;
  const quiet = sineBuffer(110, sampleRate, 8192, 0.0005);  // below the RMS gate
  assert.equal(detectPitchYIN(quiet, sampleRate, 25, 400), -1);
});

test("detectPitchYIN: rejects a too-short buffer", () => {
  assert.equal(detectPitchYIN(new Float32Array(1), 44100, 25, 400), -1);
});
