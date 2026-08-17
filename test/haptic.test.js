// Known-answer tests for the in-tune haptic edge detector.
//
// The tuner buzzes once when the needle SETTLES into tune, not on every frame
// it's held there and not while it's still off pitch. shouldBuzz() is the pure
// decision function that drives that — this locks in the rising-edge behaviour.
// Run with:  npm test   (== node --test test/)

const { test } = require("node:test");
const assert = require("node:assert/strict");
const { loadTuner } = require("./harness.js");

const T = loadTuner();
const { shouldBuzz } = T;

test("shouldBuzz: fires on the rising edge (out of tune -> in tune)", () => {
  assert.equal(shouldBuzz(false, true), true);
});

test("shouldBuzz: stays silent while already in tune (no per-frame spam)", () => {
  assert.equal(shouldBuzz(true, true), false);
});

test("shouldBuzz: stays silent leaving tune (falling edge)", () => {
  assert.equal(shouldBuzz(true, false), false);
});

test("shouldBuzz: stays silent while consistently out of tune", () => {
  assert.equal(shouldBuzz(false, false), false);
});
