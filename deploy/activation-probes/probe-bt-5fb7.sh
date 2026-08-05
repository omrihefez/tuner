#!/usr/bin/env bash
# Live probe (bt-5fb7): proves the deployed sw.js is the one a given git ref
# actually shipped, not a stale bundle Vercel silently kept serving.
#
# scripts/check-sw-cache-bump.js already catches "changed a cached asset
# without bumping CACHE" — but it only ever diffs two git refs at COMMIT
# time. It has no way to know what's actually live: a deploy that silently
# failed, or an edge cache serving a stale build, would leave the real
# sw.js lagging behind HEAD indefinitely with nothing to catch it. This
# probe closes that gap by reading the CACHE version off the real served
# sw.js and comparing it to the ref's source, not the local file.
#
# Usage: probe-live-sw-cache.sh [ref] [url]
#   ref  git ref to compare against (default: HEAD)
#   url  live sw.js URL (default: https://bass.omrihefez.com/sw.js)
set -euo pipefail

REF="${1:-HEAD}"
URL="${2:-https://bass.omrihefez.com/sw.js}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

extract_cache() {
  grep -oE 'const[[:space:]]+CACHE[[:space:]]*=[[:space:]]*"[^"]+"' | grep -oE '"[^"]+"' | tr -d '"'
}

expected="$(git -C "$ROOT" show "$REF:sw.js" | extract_cache || true)"
if [ -z "$expected" ]; then
  echo "probe-bt-5fb7: FAIL - could not find \`const CACHE = \"...\"\` in $REF:sw.js"
  exit 1
fi

live="$(curl -fsS "$URL" | extract_cache || true)"
if [ -z "$live" ]; then
  echo "probe-bt-5fb7: FAIL - could not fetch/parse CACHE from $URL"
  exit 1
fi

if [ "$live" = "$expected" ]; then
  echo "probe-bt-5fb7: PASS - live CACHE ($live) matches $REF ($expected)"
  exit 0
else
  echo "probe-bt-5fb7: FAIL - live CACHE ($live) does not match $REF ($expected) - deploy did not ship, or is being served stale"
  exit 1
fi
