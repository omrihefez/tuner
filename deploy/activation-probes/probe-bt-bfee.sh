#!/usr/bin/env bash
# Live probe (bt-bfee): proves the deployed site no longer sends
# `Access-Control-Allow-Origin: *` alongside `Cross-Origin-Resource-Policy:
# same-origin` — those two headers stated opposite intents on the same
# response, and the `*` was a Vercel platform default never present in
# vercel.json, so no config-reading test could ever see it. Same bar as
# probe-bt-188e.sh: fetches the real served headers over HTTPS.
#
# Reuses scripts/check-cors-corp-consistency.sh rather than re-implementing
# the same header logic a second time; that script already takes CHECK_HOST.
#
# Usage: probe-bt-bfee.sh [host]
#   host  live host to fetch headers from (default: bass.omrihefez.com)
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOST="${1:-bass.omrihefez.com}"

if CHECK_HOST="$HOST" bash "$HERE/../../scripts/check-cors-corp-consistency.sh"; then
  echo "probe-bt-bfee: PASS - live Access-Control-Allow-Origin no longer contradicts Cross-Origin-Resource-Policy"
  exit 0
fi
echo "probe-bt-bfee: FAIL - live headers still contradict each other"
exit 1
