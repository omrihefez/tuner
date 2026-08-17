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
// If `elementsById` is passed, appendChild/insertBefore/setAttribute("id", …)
// register the child there — lets getElementById find elements tuner.js creates
// and inserts at runtime (bt-4b38's diag-copy button), not just static ones.
function makeEl(elementsById) {
  const el = {
    textContent: "",
    value: "",
    disabled: false,
    scrollTop: 0,
    scrollHeight: 0,
    innerHTML: "",
    className: "",
    id: "",
    hidden: false,
    children: [],
    classList: { add() {}, remove() {}, toggle() {}, contains() { return false; } },
    style: {},
    dataset: {},
    _listeners: {},
    addEventListener(type, fn) { (el._listeners[type] ||= []).push(fn); },
    removeEventListener() {},
    appendChild(c) { el.children.push(c); if (elementsById && c.id) elementsById.set(c.id, c); return c; },
    insertBefore(c, ref) {
      const idx = el.children.indexOf(ref);
      if (idx === -1) el.children.push(c); else el.children.splice(idx, 0, c);
      if (elementsById && c.id) elementsById.set(c.id, c);
      return c;
    },
    removeChild() {},
    remove() {},
    setAttribute(k, v) { if (k === "id") { el.id = v; if (elementsById) elementsById.set(v, el); } },
    getAttribute() { return null; },
    querySelector() { return makeEl(elementsById); },
    querySelectorAll() { return []; },
    focus() {},
    click() { (el._listeners.click || []).forEach((fn) => fn({})); },
  };
  return el;
}

// ids that must resolve to null when nothing has registered them — lets a test
// assert a control tuner.js creates conditionally (e.g. only when DIAG_ENABLED)
// is genuinely ABSENT, not just standing in for the harness's generic fallback.
const NO_FALLBACK_IDS = new Set(["diag-copy-btn", "diag-copy-status"]);

function buildSandbox(overrides = {}) {
  const elementsById = new Map();
  // Pre-seed the two static diag elements as stable singletons (real index.html
  // has them as fixed markup) so repeated getElementById("diag-log") calls from
  // diag() accumulate onto the SAME element instead of each returning a fresh,
  // empty one — needed for the diag-copy tests to see real accumulated log text.
  const diagLogEl = makeEl(elementsById);
  diagLogEl.id = "diag-log";
  elementsById.set("diag-log", diagLogEl);
  const diagPanelEl = makeEl(elementsById);
  diagPanelEl.id = "diag-panel";
  diagPanelEl.hidden = true;
  elementsById.set("diag-panel", diagPanelEl);

  const documentStub = {
    getElementById(id) {
      if (elementsById.has(id)) return elementsById.get(id);
      return NO_FALLBACK_IDS.has(id) ? null : makeEl(elementsById);
    },
    querySelector() { return makeEl(elementsById); },
    querySelectorAll() { return []; },
    createElement() { return makeEl(elementsById); },
    createTextNode(t) { return { textContent: String(t) }; },
    createRange: overrides.createRange || function createRange() {
      return { selectNodeContents() {} };
    },
    body: makeEl(elementsById),
    addEventListener() {},
  };

  const locationStub = { protocol: "https:", host: "test.local", search: overrides.search || "", reload() {} };

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
    clipboard: overrides.clipboardWriteText
      ? { writeText: overrides.clipboardWriteText }
      : undefined,
    share: overrides.share,
  };

  const windowStub = {
    addEventListener() {},
    AudioContext: overrides.AudioContext || function AudioContext() {},
    webkitAudioContext: undefined,
    requestAnimationFrame() { return 0; },
    cancelAnimationFrame() {},
    Promise,
    location: locationStub,
    getSelection: overrides.getSelection || function getSelection() {
      return { removeAllRanges() {}, addRange() {} };
    },
    ...(overrides.caches ? { caches: overrides.caches } : {}),
  };

  const localStorageStub = {
    _m: new Map(),
    getItem(k) { return this._m.has(k) ? this._m.get(k) : null; },
    setItem(k, v) { this._m.set(k, String(v)); },
    removeItem(k) { this._m.delete(k); },
  };
  if (overrides.diagEnabled) localStorageStub._m.set("tuner:debug", "1");

  const sandbox = {
    document: documentStub,
    window: windowStub,
    navigator: navigatorStub,
    location: locationStub,
    localStorage: localStorageStub,
    performance: { now: overrides.now || function now() { return 0; } },
    requestAnimationFrame() { return 0; },
    cancelAnimationFrame() {},
    console,
    Math, JSON, Date, Float32Array, Number, Array, Object, String, parseFloat, parseInt, isNaN,
    setTimeout, clearTimeout,
    ...(overrides.caches ? { caches: overrides.caches } : {}),
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
  "buildAnnouncement",
  "shouldAnnounce",
  "state",
  "INSTRUMENTS",
  "NOTE_NAMES",
  "start",
  "stop",
  "tick",
  "tickInner",
  "playReferenceTone",
  "copyDiagLog",
  "buildDiagPayload",
  "getDiagCacheVersion",
];

function loadTuner(overrides = {}) {
  const source = fs.readFileSync(TUNER_PATH, "utf8");
  const epilogue = `\n;globalThis.__exports = { ${EXPORT_NAMES.join(", ")} };\n`;
  const sandbox = buildSandbox(overrides);
  vm.createContext(sandbox);
  vm.runInContext(source + epilogue, sandbox, { filename: "tuner.js" });
  return { ...sandbox.__exports, document: sandbox.document };
}

module.exports = { loadTuner };
