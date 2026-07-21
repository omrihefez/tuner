// Regression test for bt-8e75: if AudioContext/analyser setup throws after
// getUserMedia already resolved, start() must stop the live MediaStreamTrack
// and clear state.micStream — otherwise the OS mic indicator stays on and the
// next Start click leaks a second stream.
//
// Run with:  npm test   (== node --test test/)

const { test } = require("node:test");
const assert = require("node:assert/strict");
const { loadTuner } = require("./harness.js");

// Wait a few macrotask turns for the getUserMedia().then().catch() chain to settle.
function flush() {
  return new Promise((resolve) => setTimeout(resolve, 20));
}

test("start(): AudioContext throwing after getUserMedia resolves stops the mic track and clears state", async () => {
  let stopCalls = 0;
  const fakeTrack = { stop() { stopCalls++; } };
  const fakeStream = {
    getAudioTracks: () => [fakeTrack],
    getTracks: () => [fakeTrack],
  };

  const T = loadTuner({
    getUserMedia() { return Promise.resolve(fakeStream); },
    AudioContext: function AudioContext() { throw new Error("ctx limit reached"); },
  });

  T.start();
  await flush();

  assert.equal(stopCalls, 1, "the live MediaStreamTrack must be stop()ped on setup failure");
  assert.equal(T.state.micStream, null, "state.micStream must be cleared so the next Start doesn't leak a 2nd stream");
  assert.equal(T.state.audioCtx, null, "state.audioCtx must be cleared on setup failure");
  assert.equal(T.state.analyser, null, "state.analyser must be cleared on setup failure");
});

test("start(): a source/analyser failure after AudioContext succeeds also stops the track and closes the context", async () => {
  let stopCalls = 0;
  let closeCalls = 0;
  const fakeTrack = { stop() { stopCalls++; } };
  const fakeStream = {
    getAudioTracks: () => [fakeTrack],
    getTracks: () => [fakeTrack],
  };

  const T = loadTuner({
    getUserMedia() { return Promise.resolve(fakeStream); },
    AudioContext: function AudioContext() {
      this.close = () => { closeCalls++; };
      this.createMediaStreamSource = () => { throw new Error("createMediaStreamSource failed"); };
    },
  });

  T.start();
  await flush();

  assert.equal(stopCalls, 1, "the live MediaStreamTrack must be stop()ped on setup failure");
  assert.equal(closeCalls, 1, "the partially-created AudioContext must be closed");
  assert.equal(T.state.micStream, null, "state.micStream must be cleared so the next Start doesn't leak a 2nd stream");
  assert.equal(T.state.audioCtx, null, "state.audioCtx must be cleared on setup failure");
});

test("start(): the happy path is unaffected — stream and analyser stay wired up", async () => {
  const fakeTrack = { stop() {} };
  const fakeStream = {
    getAudioTracks: () => [fakeTrack],
    getTracks: () => [fakeTrack],
  };

  const T = loadTuner({
    getUserMedia() { return Promise.resolve(fakeStream); },
    AudioContext: function AudioContext() {
      this.createMediaStreamSource = () => ({ connect() {} });
      this.createAnalyser = () => ({ fftSize: 0, smoothingTimeConstant: 0 });
      this.close = () => {};
    },
  });

  T.start();
  await flush();

  assert.equal(T.state.micStream, fakeStream);
  assert.ok(T.state.audioCtx, "audioCtx should be set on success");
  assert.ok(T.state.analyser, "analyser should be set on success");
});
