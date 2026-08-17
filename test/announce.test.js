// Known-answer tests for the aria-live announcer that reads the cents/note
// readout to screen readers.
//
// The visual readout refreshes every animation frame (60fps); a screen reader
// must not — buildAnnouncement() rounds cents to a coarse grid and
// shouldAnnounce() throttles + dedupes updates so the live region doesn't
// turn into unusable chatter. Run with: npm test  (== node --test test/)

const { test } = require("node:test");
const assert = require("node:assert/strict");
const { loadTuner } = require("./harness.js");

const T = loadTuner();
const { buildAnnouncement, shouldAnnounce } = T;

test("buildAnnouncement: in tune reads a clean confirmation", () => {
  assert.equal(buildAnnouncement("E1", 0, true), "E1, in tune");
});

test("buildAnnouncement: flat direction is named, magnitude rounded to the grid", () => {
  assert.equal(buildAnnouncement("A1", -12, false), "A1, 10 cents flat");
});

test("buildAnnouncement: sharp direction is named, magnitude rounded to the grid", () => {
  assert.equal(buildAnnouncement("D2", 23, false), "D2, 25 cents sharp");
});

test("buildAnnouncement: rounds to zero collapses to the in-tune sentence", () => {
  assert.equal(buildAnnouncement("G2", 2, false), "G2, in tune");
});

test("shouldAnnounce: silent when the text hasn't changed (no per-frame repeats)", () => {
  assert.equal(shouldAnnounce(1000, 0, "E1, in tune", "E1, in tune", false), false);
});

test("shouldAnnounce: silent on a changed text within the throttle window", () => {
  assert.equal(shouldAnnounce(500, 0, "E1, 10 cents flat", "E1, 15 cents flat", false), false);
});

test("shouldAnnounce: fires on a changed text once the throttle window has elapsed", () => {
  assert.equal(shouldAnnounce(1300, 0, "E1, 10 cents flat", "E1, 15 cents flat", false), true);
});

test("shouldAnnounce: entering tune jumps the throttle queue immediately", () => {
  assert.equal(shouldAnnounce(50, 0, "E1, 10 cents flat", "E1, in tune", true), true);
});
