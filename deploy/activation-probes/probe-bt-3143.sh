#!/usr/bin/env bash
# Live probe (bt-3143): proves the deployed sw.js actually contains the
# resolved-non-ok cache-fallback fix, not just that it's committed to main.
#
# This fix doesn't bump CACHE (no ASSETS-listed file changed, only sw.js's
# own fetch-handler logic), so probe-bt-5fb7.sh's CACHE-version comparison
# can't tell old sw.js from new. Instead this probe byte-compares the full
# live sw.js body against a given git ref's source.
#
# Usage: probe-bt-3143.sh [ref] [url]
#   ref  git ref to compare against (default: HEAD)
#   url  live sw.js URL (default: https://bass.omrihefez.com/sw.js)
set -euo pipefail

REF="${1:-HEAD}"
URL="${2:-https://bass.omrihefez.com/sw.js}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

expected="$(git -C "$ROOT" show "$REF:sw.js")"
live="$(curl -fsS "$URL")"

if [ -z "$live" ]; then
  echo "probe-bt-3143: FAIL - could not fetch $URL"
  exit 1
fi

if ! grep -q 'caches.match(e.request).then(r => r || resp)' <<<"$expected"; then
  echo "probe-bt-3143: FAIL - $REF:sw.js does not contain the resolved-non-ok fallback fix"
  exit 1
fi

if [ "$live" = "$expected" ]; then
  echo "probe-bt-3143: PASS - live sw.js matches $REF and contains the resolved-non-ok cache fallback"
  exit 0
else
  if grep -q 'caches.match(e.request).then(r => r || resp)' <<<"$live"; then
    echo "probe-bt-3143: PASS - live sw.js differs from $REF elsewhere but already contains the resolved-non-ok cache fallback"
    exit 0
  fi
  echo "probe-bt-3143: FAIL - live sw.js does not match $REF and lacks the resolved-non-ok cache fallback - deploy did not ship, or is being served stale"
  exit 1
fi
