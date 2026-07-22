// Test harness for the bass-tuner pitch math.
//
// tuner.js is a plain browser script (no module exports) that also wires up the
// DOM and mic on load. To unit-test its *pure* pitch-math functions in Node
// without touching the shipped file, we evaluate the real tuner.js source inside
// a `vm` sandbox that stubs just enough of the browser (DOM/window/navigator/
// localStorage) for its top-level wiring to run without throwing, then append a
// tiny epilogue that hands the functions back out.
//
// This tests the ACTUAL deployed code — no re-implementation, no copy — so the
// known-answer tests stay honest: if tuner.js's math drifts, the tests fail.

const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");

const TUNER_PATH = path.join(__dirname, "..", "tuner.js");

// A permissive fake DOM element: every method is a no-op, every accessed child
// object (classList/style/dataset) is itself inert, and appendChild is tracked.
function makeEl() {
  const el = {
    textContent: "",
    value: "",
    disabled: false,
    scrollTop: 0,
    scrollHeight: 0,
    innerHTML: "",
    className: "",
    id: "",
    children: [],
    classList: { add() {}, remove() {}, toggle() {}, contains() { return false; } },
    style: {},
    dataset: {},
    addEventListener() {},
    removeEventListener() {},
    appendChild(c) { el.children.push(c); return c; },
    removeChild() {},
    remove() {},
    setAttribute() {},
    getAttribute() { return null; },
    querySelector() { return makeEl(); },
    querySelectorAll() { return []; },
    focus() {},
    click() {},
  };
  return el;
}

function buildSandbox(overrides = {}) {
  const documentStub = {
    getElementById() { return makeEl(); },
    querySelector() { return makeEl(); },
    querySelectorAll() { return []; },
    createElement() { return makeEl(); },
    createTextNode(t) { return { textContent: String(t) }; },
    body: makeEl(),
    addEventListener() {},
  };

  const locationStub = { protocol: "https:", host: "test.local", reload() {} };

  const navigatorStub = {
    userAgent: "node-test-harness",
    mediaDevices: {
      getUserMedia: overrides.getUserMedia
        || function getUserMedia() { return Promise.resolve({ getAudioTracks: () => [] }); },
    },
    permissions: { query() { return Promise.resolve({ state: "prompt", addEventListener() {} }); } },
    serviceWorker: {
      register() { return Promise.resolve(null); },
      addEventListener() {},
      getRegistrations() { return Promise.resolve([]); },
    },
  };

  const windowStub = {
    addEventListener() {},
    AudioContext: overrides.AudioContext || function AudioContext() {},
    webkitAudioContext: undefined,
    requestAnimationFrame() { return 0; },
    cancelAnimationFrame() {},
    Promise,
    location: locationStub,
  };

  const localStorageStub = {
    _m: new Map(),
    getItem(k) { return this._m.has(k) ? this._m.get(k) : null; },
    setItem(k, v) { this._m.set(k, String(v)); },
    removeItem(k) { this._m.delete(k); },
  };

  const sandbox = {
    document: documentStub,
    window: windowStub,
    navigator: navigatorStub,
    location: locationStub,
    localStorage: localStorageStub,
    performance: { now() { return 0; } },
    requestAnimationFrame() { return 0; },
    cancelAnimationFrame() {},
    console,
    Math, JSON, Date, Float32Array, Number, Array, Object, String, parseFloat, parseInt, isNaN,
    setTimeout, clearTimeout,
  };
  sandbox.globalThis = sandbox;
  return sandbox;
}

// Names to hand back out of the sandbox. All are top-level `function`/`const`
// declarations in tuner.js and thus in scope for the appended epilogue.
const EXPORT_NAMES = [
  "midiToFreq",
  "freqToMidi",
  "noteLabel",
  "closestString",
  "medianPitch",
  "detectPitchYIN",
  "freqRange",
  "currentTuning",
  "shouldBuzz",
  "state",
  "INSTRUMENTS",
  "NOTE_NAMES",
  "start",
  "stop",
];

function loadTuner(overrides) {
  const source = fs.readFileSync(TUNER_PATH, "utf8");
  const epilogue = `\n;globalThis.__exports = { ${EXPORT_NAMES.join(", ")} };\n`;
  const sandbox = buildSandbox(overrides);
  vm.createContext(sandbox);
  vm.runInContext(source + epilogue, sandbox, { filename: "tuner.js" });
  return sandbox.__exports;
}

module.exports = { loadTuner };
