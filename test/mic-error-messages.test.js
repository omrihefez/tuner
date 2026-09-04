// bt-b7e7: when the tuner stops working, the ONLY self-service diagnosis a user
// has is the red text in #mic-status. Two branches were wrong:
//
//   1. NotReadableError had no branch at all. That is the case where the mic is
//      held by another app or by a backgrounded copy of the tuner itself — the
//      exact leaked-stream shape bt-8e75 fixed in code — and it fell into the
//      generic bucket, reading as "Mic error: Could not start audio source".
//      A user cannot act on that sentence, and the fix (swipe the app from
//      recents) is not guessable from it.
//   2. The HTTPS branch was UNREACHABLE. On plain http the browser rejects with
//      NotAllowedError, which matched first, so the user was sent to a Chrome
//      site-settings page that cannot fix a protocol problem. The one branch
//      that names the real cause could never fire.
//
// Run with:  npm test   (== node --test test/)

const { test } = require("node:test");
const assert = require("node:assert/strict");
const { loadTuner } = require("./harness.js");

function flush() {
  return new Promise((resolve) => setTimeout(resolve, 20));
}

function rejectWith(name, message, extra = {}) {
  const err = new Error(message);
  err.name = name;
  return loadTuner({
    getUserMedia() { return Promise.reject(err); },
    ...extra,
  });
}

async function micTextAfterFailure(name, message, extra) {
  const T = rejectWith(name, message, extra);
  T.start();
  await flush();
  return T.document.getElementById("mic-status").textContent;
}

test("NotReadableError names the held-microphone case and its fix", async () => {
  const text = await micTextAfterFailure("NotReadableError", "Could not start audio source");
  assert.match(text, /another app|in use|already using/i,
    "must say the mic is held by something else");
  assert.match(text, /recent|close|swipe/i,
    "must name the actual fix — closing the other app / swiping this one from recents");
  assert.doesNotMatch(text, /^Mic error:/,
    "must not fall through to the opaque generic bucket");
});

test("TrackStartError (Chrome's older alias) gets the same treatment", async () => {
  const text = await micTextAfterFailure("TrackStartError", "Could not start audio source");
  assert.match(text, /another app|in use|already using/i);
  assert.doesNotMatch(text, /^Mic error:/);
});

test("over http the message names the protocol, not Chrome site settings", async () => {
  // The browser really does reject with NotAllowedError on an insecure origin,
  // which is why ordering matters: the protocol check has to win.
  const text = await micTextAfterFailure("NotAllowedError", "Permission denied", { protocol: "http:" });
  assert.match(text, /HTTPS/i, "must name the protocol as the cause");
  assert.doesNotMatch(text, /Site settings/i,
    "must NOT send the user to a settings page that cannot fix an http origin");
});

test("a genuine permission denial over https still gets the Chrome path", async () => {
  const text = await micTextAfterFailure("NotAllowedError", "Permission denied");
  assert.match(text, /Site settings/i);
  assert.match(text, /bass\.omrihefez\.com/);
});

test("NotFoundError still reports no microphone", async () => {
  const text = await micTextAfterFailure("NotFoundError", "Requested device not found");
  assert.match(text, /No microphone found/i);
});

test("an unrecognised error still surfaces something rather than staying silent", async () => {
  const text = await micTextAfterFailure("WeirdNewError", "something unprecedented");
  assert.match(text, /something unprecedented|WeirdNewError/,
    "the generic bucket must still carry the underlying message");
});
