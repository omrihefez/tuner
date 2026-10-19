---
id: bt-d010
title: vercel-headers.test.js matches HSTS and Permissions-Policy by SUBSTRING, so deleting
  includeSubDomains or re-allowing camera and geolocation keeps the pre-push suite green
status: done
priority: p3
tags:
  - http-headers
created: 2026-10-19
filed:
  owner: meni-worker/board-refill-work-discov-94eabb
  at: 2026-10-19T05:07:38Z
done:
  at: 2026-10-19T07:13:34Z
  by: capacity-engine
evidence:
  - type: commit
    value: 4d5969b71ab11c479db7f23f116cd26a016f2d19
    verified: 2026-10-19T07:13:34Z
  - type: test
    cmd: node --test test/vercel-headers.test.js
    exit: 0
    at: 2026-10-19T07:13:34Z
    log: evidence/bt-d010-2026-10-19T07-13-34Z-test.txt
    sha256: 077fdc6e9387ec5e7853a0fe24a206c68ad231e7f532abfbec6fee4ff5db4550
    bytes: 2502
  - type: note
    value: "Red demonstrated pre-fix: stripping includeSubDomains and narrowing Permissions-Policy both
      passed the old substring assertions; after the fix both fail (quoted in report). Other 5
      REQUIRED_HEADERS entries were already exact matches, not prefixes."
---

`test/vercel-headers.test.js` checks each required header with a SUBSTRING match against
a deliberately short expected value, so it stays green through real regressions in the
two headers whose full value carries the protection.

The loop, `test/vercel-headers.test.js:56-66`:

```
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
```

and the table it iterates, lines 41-49, where two entries are strict prefixes of what
`vercel.json` actually ships:

```
"Strict-Transport-Security": "max-age=31536000",        <- vercel.json:20 ships "max-age=31536000; includeSubDomains"
"Permissions-Policy": "microphone=(self)",              <- vercel.json ships "camera=(), microphone=(self), geolocation=()"
```

CONCRETE FAILURE SCENARIOS, both passing today and after the regression:

1. Delete `; includeSubDomains` from `vercel.json`'s `Strict-Transport-Security`. The
   remaining value still contains `max-age=31536000`, so this suite is green. The
   protection for every `*.omrihefez.com` subdomain served off this project is gone.
2. Narrow `Permissions-Policy` to just `microphone=(self)`, re-allowing camera and
   geolocation by browser default. Still contains the expected substring. Still green.

THE SHARP PART IS WHO ELSE WOULD HAVE CAUGHT IT. This repo's OWN
`scripts/audit-domains.sh` asserts both properties — `check_hsts()` at line 395-397
prints `DRIFT ... missing includeSubDomains` and sets `FAIL=1`, and the
Permissions-Policy checks assert the full value — but that script probes the LIVE host
on a daily cron (`10 6`), i.e. after the regression has already shipped to
bass.omrihefez.com. The pre-push suite, the gate that could have refused the push, is
the blind one. So the repo holds the correct assertion and the wrong one at the same
time, in two files, and the weaker one runs first.

Note `check_hsts()`'s own history says this exact lesson was already learned once on the
audit side: its `bt-8c53` comment records that "presence alone used to be enough, so
`max-age=0` ... and a header missing includeSubDomains both read as OK. Now the VALUE is
asserted." That correction never reached `test/vercel-headers.test.js`.

The 1-year max-age itself is NOT the defect and must not be "fixed" here —
`audit-domains.sh:354-358` documents 31536000 as the deliberate floor, chosen because
raising it later is free while forcing a host upward would make it fight the check to
deploy. Leave the value; fix the assertion.

DONE WHEN
1. `REQUIRED_HEADERS` asserts the full shipped value for `Permissions-Policy`, and HSTS
   is asserted structurally the way `check_hsts()` does it — `max-age` parsed and
   floored at 31536000, `includeSubDomains` present — rather than by substring. The two
   checks should agree by construction, not by coincidence; sourcing the floor from one
   place is better than typing 31536000 twice.
2. Demonstrated RED first: with the new assertions in, delete `; includeSubDomains` from
   `vercel.json`, watch the suite fail, revert. Quote that failing run in the closing
   note — this task is about a test that cannot fail, so a green run proves nothing.
3. While in the file, check the other five entries in `REQUIRED_HEADERS` for the same
   prefix-of-the-real-value shape and say what you found, even if the answer is "the
   other five are exact".

## Log
- 2026-10-19 claimed by capacity-engine
- 2026-10-19 done by capacity-engine — commit 4d5969b71ab1, test `node --test test/vercel-headers.test.js` exit 0 (log: evidence/bt-d010-2026-10-19T07-13-34Z-test.txt)
