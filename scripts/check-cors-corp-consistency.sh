#!/usr/bin/env bash
# bt-bfee: bass.omrihefez.com sent `Access-Control-Allow-Origin: *` on top of
# `Cross-Origin-Resource-Policy: same-origin` — the two headers state
# opposite intents on the same response, and neither grep nor the old
# vercel.json-reading test could ever catch it, because the `*` is not in
# vercel.json at all. It's a Vercel static-file-handler platform default
# that lands on top of this repo's own `headers` block.
#
# Asserts the LIVE response headers, not the presence of a string in
# vercel.json — same rationale as check-permissions-policy.sh. CURL_CMD is
# overridable so the companion test is hermetic.
#
# The decision taken for bt-bfee was to keep Cross-Origin-Resource-Policy:
# same-origin (the app's deliberate posture) and scope
# Access-Control-Allow-Origin down to the site's own origin instead of "*",
# rather than drop CORP/COOP. So this checks both: CORP must still read
# same-origin, and ACAO must be present, non-wildcard, and equal to the
# site's own https origin.
set -uo pipefail

HOST="${CHECK_HOST:-bass.omrihefez.com}"
EXPECTED_CORP="same-origin"
EXPECTED_ACAO="https://$HOST"

resp=$("${CURL_CMD:-curl}" -s -D - -o /dev/null --max-time 10 "https://$HOST/")

corp_line=$(echo "$resp" | grep -i '^cross-origin-resource-policy:' | head -1)
acao_line=$(echo "$resp" | grep -i '^access-control-allow-origin:' | head -1)

if [ -z "$corp_line" ]; then
  echo "DRIFT  $HOST -> no Cross-Origin-Resource-Policy header sent" >&2
  exit 1
fi
corp_value="${corp_line#*:}"
corp_value="$(echo "$corp_value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/\r$//')"
if [ "$corp_value" != "$EXPECTED_CORP" ]; then
  echo "DRIFT  $HOST -> Cross-Origin-Resource-Policy: $corp_value (expected: $EXPECTED_CORP)" >&2
  exit 1
fi

if [ -z "$acao_line" ]; then
  echo "DRIFT  $HOST -> no Access-Control-Allow-Origin header sent" >&2
  exit 1
fi
acao_value="${acao_line#*:}"
acao_value="$(echo "$acao_value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/\r$//')"

if [ "$acao_value" = "*" ]; then
  echo "DRIFT  $HOST -> Access-Control-Allow-Origin: * contradicts Cross-Origin-Resource-Policy: $corp_value" >&2
  exit 1
fi

if [ "$acao_value" != "$EXPECTED_ACAO" ]; then
  echo "DRIFT  $HOST -> Access-Control-Allow-Origin: $acao_value (expected: $EXPECTED_ACAO)" >&2
  exit 1
fi

echo "OK     $HOST -> Cross-Origin-Resource-Policy: $corp_value, Access-Control-Allow-Origin: $acao_value"
exit 0
