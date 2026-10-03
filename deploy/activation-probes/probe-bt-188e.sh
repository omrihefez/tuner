#!/usr/bin/env bash
# Live probe (bt-188e): proves the deployed site's CSP actually carries
# report-uri/report-to and a matching Reporting-Endpoints header, not just
# the local vercel.json. Fetches the real served headers over HTTPS, the
# same bar as probe-bt-5fb7.sh.
#
# Usage: probe-bt-188e.sh [url]
#   url  live URL to fetch headers from (default: https://bass.omrihefez.com/)
set -euo pipefail

URL="${1:-https://bass.omrihefez.com/}"

headers="$(curl -fsS -D - -o /dev/null "$URL")"

csp="$(printf '%s' "$headers" | grep -i '^content-security-policy:' || true)"
reporting="$(printf '%s' "$headers" | grep -i '^reporting-endpoints:' || true)"

fail=0

if ! printf '%s' "$csp" | grep -q 'report-uri https://meniapp-api.omrihefez.com/api/csp-report'; then
  echo "probe-bt-188e: FAIL - live CSP is missing the report-uri directive"
  fail=1
fi

if ! printf '%s' "$csp" | grep -q 'report-to csp-endpoint'; then
  echo "probe-bt-188e: FAIL - live CSP is missing the report-to directive"
  fail=1
fi

if ! printf '%s' "$reporting" | grep -q 'csp-endpoint="https://meniapp-api.omrihefez.com/api/csp-report"'; then
  echo "probe-bt-188e: FAIL - live Reporting-Endpoints header is missing or does not match"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "probe-bt-188e: PASS - live CSP reports violations to the hub sink"
  exit 0
fi
exit 1
