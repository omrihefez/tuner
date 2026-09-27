#!/usr/bin/env bash
# bt-40c5: bass.omrihefez.com calls getUserMedia (tuner.js:616) but sent no
# Permissions-Policy header, so the page inherited the browser default —
# every policy-controlled feature (camera, geolocation, payment, USB, ...)
# allowed, not just the microphone this app actually uses.
#
# Asserts the LIVE response header, not the presence of a string in
# vercel.json — a header block can be present and still not reach the
# browser (wrong route glob, a later header block overriding it, a stale
# deploy). CURL_CMD is overridable so the companion test is hermetic.
#
# The exact value matters more than presence: `microphone=()` (empty
# allowlist) would refuse getUserMedia in the page itself and silently break
# the tuner, so this checks the full value, not just that the header exists.
set -uo pipefail

HOST="${CHECK_HOST:-bass.omrihefez.com}"
EXPECTED="camera=(), microphone=(self), geolocation=()"

resp=$("${CURL_CMD:-curl}" -s -D - -o /dev/null --max-time 10 "https://$HOST/")
line=$(echo "$resp" | grep -i '^permissions-policy:' | head -1)

if [ -z "$line" ]; then
  echo "DRIFT  $HOST -> no Permissions-Policy header sent" >&2
  exit 1
fi

value="${line#*:}"
value="$(echo "$value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/\r$//')"

if [ "$value" != "$EXPECTED" ]; then
  echo "DRIFT  $HOST -> Permissions-Policy: $value (expected: $EXPECTED)" >&2
  exit 1
fi

echo "OK     $HOST -> Permissions-Policy: $value"
exit 0
