// Regression test for bt-a66f: the header comment (tuner.js:1-3) claims the tuner
// "samples at 22.05 kHz worth of resolution", but start() used to create a plain
// AudioContext() that runs at the device's native rate (44.1/48 kHz) — 2x the YIN
// diff-loop cost the design assumes. start() must now request 22050 explicitly,
// with a fallback to the device default for engines that reject the option.
//
// Run with:  npm test   (== node --test test/)

const { test } = require("node:test");
const assert = require("node:assert/strict");
const { loadTuner } = require("./harness.js");

function flush() {
  return new Promise((resolve) => setTimeout(resolve, 20));
}

test("start(): requests a 22050 Hz AudioContext to match the stated 22.05kHz design", async () => {
  const seenOptions = [];
  const fakeTrack = { stop() {} };
  const fakeStream = { getAudioTracks: () => [fakeTrack], getTracks: () => [fakeTrack] };

  const T = loadTuner({
    getUserMedia() { return Promise.resolve(fakeStream); },
    AudioContext: function AudioContext(opts) {
      seenOptions.push(opts);
      this.sampleRate = (opts && opts.sampleRate) || 44100;
      this.createMediaStreamSource = () => ({ connect() {} });
      this.createAnalyser = () => ({ fftSize: 0, smoothingTimeConstant: 0 });
      this.close = () => {};
    },
  });

  T.start();
  await flush();

  assert.equal(seenOptions.length, 1, "AudioContext should be constructed exactly once on the happy path");
  assert.equal(seenOptions[0].sampleRate, 22050, "must request 22050 Hz explicitly");
  assert.equal(Object.keys(seenOptions[0]).length, 1, "should pass only sampleRate, nothing else");
  assert.equal(T.state.audioCtx.sampleRate, 22050);
});

test("start(): falls back to the device-default AudioContext if the sampleRate option is rejected", async () => {
  let calls = 0;
  const fakeTrack = { stop() {} };
  const fakeStream = { getAudioTracks: () => [fakeTrack], getTracks: () => [fakeTrack] };

  const T = loadTuner({
    getUserMedia() { return Promise.resolve(fakeStream); },
    AudioContext: function AudioContext(opts) {
      calls++;
      if (opts && opts.sampleRate) throw new Error("NotSupportedError: sampleRate not supported");
      this.sampleRate = 44100;
      this.createMediaStreamSource = () => ({ connect() {} });
      this.createAnalyser = () => ({ fftSize: 0, smoothingTimeConstant: 0 });
      this.close = () => {};
    },
  });

  T.start();
  await flush();

  assert.equal(calls, 2, "should retry with no options after the sampleRate request throws");
  assert.ok(T.state.audioCtx, "audioCtx should still end up set via the fallback");
  assert.equal(T.state.audioCtx.sampleRate, 44100);
});
