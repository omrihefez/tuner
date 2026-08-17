// Tests for bt-4b38: the diagnostic panel had no way to get its log off the
// device (no copy, share, or beacon). tuner.js now creates a "Copy diagnostics"
// control inside the panel, but ONLY when DIAG_ENABLED — it must not exist at
// all for normal users, and the copied payload must answer "which bundle is
// this device actually running" via the active service-worker cache version.
//
// Run with: npm test  (== node --test test/)

const { test } = require("node:test");
const assert = require("node:assert/strict");
const { loadTuner } = require("./harness.js");

test("diag copy control is absent when DIAG_ENABLED is false (default, no ?debug/localStorage)", () => {
  const T = loadTuner();
  assert.equal(T.document.getElementById("diag-copy-btn"), null);
  assert.equal(T.document.getElementById("diag-copy-status"), null);
});

test("diag copy control is present when DIAG_ENABLED via localStorage[\"tuner:debug\"]", () => {
  const T = loadTuner({ diagEnabled: true });
  const btn = T.document.getElementById("diag-copy-btn");
  assert.ok(btn, "copy button should exist when DIAG_ENABLED");
  assert.equal(btn.textContent, "Copy diagnostics");
});

test("copyDiagLog: writes the accumulated log plus the active SW cache version to the clipboard", async () => {
  let written = null;
  const T = loadTuner({
    diagEnabled: true,
    clipboardWriteText: (text) => { written = text; return Promise.resolve(); },
    caches: { keys: () => Promise.resolve(["tuner-v10"]) },
  });

  await T.copyDiagLog();

  assert.ok(written, "clipboard.writeText should have been called");
  assert.match(written, /tuner-v10/, "payload must include the active SW cache version");
  assert.match(written, /page loaded/, "payload must include the accumulated diag log");
  assert.equal(T.document.getElementById("diag-copy-status").textContent, "Copied to clipboard");
});

test("copyDiagLog: falls back to navigator.share when clipboard is unavailable", async () => {
  let shared = null;
  const T = loadTuner({
    diagEnabled: true,
    share: (data) => { shared = data; return Promise.resolve(); },
    caches: { keys: () => Promise.resolve([]) },
  });

  await T.copyDiagLog();

  assert.ok(shared, "navigator.share should have been called");
  assert.match(shared.text, /page loaded/);
  assert.equal(T.document.getElementById("diag-copy-status").textContent, "Shared");
});

test("copyDiagLog: falls back to select-all when neither clipboard nor share exist", async () => {
  let selected = false;
  const T = loadTuner({
    diagEnabled: true,
    getSelection: () => ({
      removeAllRanges() {},
      addRange() { selected = true; },
    }),
  });

  await T.copyDiagLog();

  assert.ok(selected, "the log text should have been selected for manual copy");
  assert.equal(T.document.getElementById("diag-copy-status").textContent, "Selected — copy manually");
});

test("buildDiagPayload: reports when the Cache Storage API itself isn't available", async () => {
  const T = loadTuner({ diagEnabled: true });
  const payload = await T.buildDiagPayload();
  assert.match(payload, /no Cache Storage API/);
});
