// Tests for vercel.json's security header block.
//
// bt-d517: the header block is the entire security posture of the app (HSTS,
// frame-ancestors, CSP, COOP/CORP, sw.js no-store) and nothing checked it — a
// careless edit could drop a header or weaken the CSP and CI would stay
// green. This mirrors check-sw-cache-bump.js's approach: read the real
// vercel.json rather than hardcoding a parallel copy of it, so the test and
// the config cannot drift apart.
// Run with:  npm test   (== node --test test/)

const { test } = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");

const VERCEL_JSON_PATH = path.join(__dirname, "..", "vercel.json");
const config = JSON.parse(fs.readFileSync(VERCEL_JSON_PATH, "utf8"));

function findRule(source) {
  return config.headers.find((rule) => rule.source === source);
}

function headerValue(rule, key) {
  const header = rule.headers.find((h) => h.key === key);
  return header && header.value;
}

const CATCH_ALL_SOURCE = "/(.*)";

const REQUIRED_HEADERS = {
  "Strict-Transport-Security": "max-age=31536000",
  "X-Content-Type-Options": "nosniff",
  "X-Frame-Options": "DENY",
  "Referrer-Policy": "no-referrer",
  "Cross-Origin-Opener-Policy": "same-origin",
  "Cross-Origin-Resource-Policy": "same-origin",
};

test("vercel.json has a catch-all header rule", () => {
  const rule = findRule(CATCH_ALL_SOURCE);
  assert.ok(rule, `expected a headers rule with source "${CATCH_ALL_SOURCE}"`);
});

for (const [key, expectedSubstring] of Object.entries(REQUIRED_HEADERS)) {
  test(`catch-all rule sets ${key}`, () => {
    const rule = findRule(CATCH_ALL_SOURCE);
    const value = headerValue(rule, key);
    assert.ok(value, `missing header "${key}" on the catch-all rule`);
    assert.ok(
      value.includes(expectedSubstring),
      `expected ${key} to include "${expectedSubstring}", got "${value}"`
    );
  });
}

test("catch-all rule sets a Content-Security-Policy with the required directives", () => {
  const rule = findRule(CATCH_ALL_SOURCE);
  const csp = headerValue(rule, "Content-Security-Policy");
  assert.ok(csp, "missing Content-Security-Policy header on the catch-all rule");

  for (const directive of [
    "default-src 'self'",
    "frame-ancestors 'none'",
    "form-action 'self'",
  ]) {
    assert.ok(csp.includes(directive), `expected CSP to include "${directive}", got "${csp}"`);
  }
});

test("sw.js has a no-store Cache-Control rule so a deploy is always reachable", () => {
  const rule = findRule("/sw.js");
  assert.ok(rule, 'expected a headers rule with source "/sw.js"');
  const value = headerValue(rule, "Cache-Control");
  assert.ok(value, "missing Cache-Control header on the /sw.js rule");
  assert.ok(value.includes("no-store"), `expected sw.js Cache-Control to include "no-store", got "${value}"`);
});
