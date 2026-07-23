// Regression test for bt-1628: playReferenceTone() plays the target pitch out of
// the speakers, which leaks acoustically into the live mic. Without a gate, the
// detector locks onto the reference pitch mid-tone and jerks the needle to the
// played note instead of the string being tuned. tickInner() must skip pitch
// detection for the ~1.2s the tone plays, then resume normally.
//
// Run with:  npm test   (== node --test test/)

const { test } = require("node:test");
const assert = require("node:assert/strict");
const { loadTuner } = require("./harness.js");

// A fake AudioContext that supports both the mic-analyser path (start()) and the
// oscillator/gain path (playReferenceTone()), and counts getFloatTimeDomainData
// calls so we can tell whether tickInner() actually ran YIN detection.
function makeFakeAudioCtx() {
  let getDataCalls = 0;
  const ctx = {
    sampleRate: 22050,
    currentTime: 0,
    createMediaStreamSource() { return { connect() {} }; },
    createAnalyser() {
      return {
        fftSize: 8192,
        smoothingTimeConstant: 0,
        getFloatTimeDomainData(buf) { getDataCalls++; buf.fill(0); },
      };
    },
    createOscillator() {
      return { type: "", frequency: { value: 0 }, connect() {}, start() {}, stop() {}, onended: null };
    },
    createGain() {
      return { gain: { setValueAtTime() {}, exponentialRampToValueAtTime() {} }, connect() {} };
    },
    resume() {},
    close() {},
  };
  return { ctx, getDataCalls: () => getDataCalls };
}

function flush() {
  return new Promise((resolve) => setTimeout(resolve, 20));
}

test("tickInner(): pitch detection is gated while the reference tone is playing", async () => {
  let t = 1000;
  const { ctx, getDataCalls } = makeFakeAudioCtx();
  const fakeTrack = { stop() {} };
  const fakeStream = { getAudioTracks: () => [fakeTrack], getTracks: () => [fakeTrack] };

  const T = loadTuner({
    now: () => t,
    getUserMedia() { return Promise.resolve(fakeStream); },
    AudioContext: function AudioContext() { return ctx; },
  });

  T.start();
  await flush();
  assert.ok(T.state.analyser, "tuner must be running (analyser wired) for this test to be meaningful");

  // start() itself runs one detection pass; baseline against that instead of 0.
  const baseline = getDataCalls();

  // Tap a locked string to play the reference tone.
  T.playReferenceTone(40);
  assert.equal(T.state.refToneGateUntil, t + 1200, "playing the tone must open a ~1.2s detection gate");

  // Immediately after: still inside the gate window — detection must be skipped.
  T.state.lastDetectTs = 0; // force the throttle to allow a run if the gate didn't block it
  T.tickInner();
  assert.equal(getDataCalls(), baseline, "YIN detection must not run while the reference tone is playing");

  // Partway through the tone: still gated.
  t += 600;
  T.state.lastDetectTs = 0;
  T.tickInner();
  assert.equal(getDataCalls(), baseline, "still within the 1.2s tone window — detection must stay gated");

  // After the tone has finished: detection resumes.
  t += 700; // total elapsed = 1300ms > 1200ms gate
  T.state.lastDetectTs = 0;
  T.tickInner();
  assert.equal(getDataCalls(), baseline + 1, "detection must resume once the reference tone has finished playing");
});

test("playReferenceTone(): does not touch the gate for callers where the tuner isn't running", () => {
  const { ctx } = makeFakeAudioCtx();
  let t = 5000;
  const T = loadTuner({ now: () => t, AudioContext: function AudioContext() { return ctx; } });

  T.state.audioCtx = null; // tuner not started — playReferenceTone opens its own ctx
  T.playReferenceTone(40);

  // No analyser means tick()/tickInner() are no-ops regardless, but the gate should
  // still be recorded consistently (harmless — nothing reads it while stopped).
  assert.equal(T.state.refToneGateUntil, t + 1200);
});
