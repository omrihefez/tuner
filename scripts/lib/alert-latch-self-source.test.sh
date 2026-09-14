#!/usr/bin/env bash
# alert-latch-self-source.test.sh — regression test for ma-87e0.
#
# The shim honours a caller-supplied $ALERT_LATCH_LIB. meniapp's own copy of
# this shim (ma-405f) crashed five scheduled guards for five days because a
# fleet caller set that variable to the shim's OWN PATH and then sourced it:
#
#   ALERT_LATCH_LIB="${ALERT_LATCH_LIB:-/home/omri/projects/meniapp/scripts/lib/alert-latch.sh}"
#   . "$ALERT_LATCH_LIB"
#
# Once alert-latch.sh became a shim (bt-ea85, 2026-09-08) that spelling made
# it source itself forever — infinite recursion, stack overflow, SIGSEGV
# (rc 139), with not one byte of the guard's own output reaching its log. No
# caller points at THIS repo's shim that way yet (ma-87e0's own finding: the
# bug was latent here, not yet triggered) — this test is what stops it from
# becoming the sixth live incident the moment one does.
#
# THIS TEST FAILS (rc 139) AGAINST THE PARENT COMMIT. Verified by hand
# 2026-09-14: case 1 segfaults against scripts/lib/alert-latch.sh from
# HEAD~1. Do not weaken it to "does it parse" — parsing was never the
# problem.
#
# Case 3 is the reason this cannot be `[ "$ALERT_LATCH_LIB" != "$self" ]`: a
# worktree checkout of the same file lives under a different (symlinked)
# root than the fixed fleet path, and a caller may spell either with `..` or
# a trailing `/.`. The comparison has to be on resolved paths or it silently
# stops protecting exactly the call sites it exists for.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHIM="$HERE/alert-latch.sh"
fails=0

check() { # <name> <spelling-of-the-shim-path>
  local name="$1" spelling="$2" out rc
  # A 20s cap so a future regression that HANGS instead of crashing is still a
  # failure rather than a wedged suite.
  out="$(ALERT_LATCH_LIB="$spelling" timeout 20 bash -c \
    'set -uo pipefail; . "$1" || exit $?; declare -F notify_and_latch >/dev/null || { echo "notify_and_latch not defined"; exit 9; }' \
    _ "$SHIM" 2>&1)"
  rc=$?
  if [ "$rc" -eq 0 ]; then
    echo "ok   — $name"
  else
    echo "FAIL — $name: rc=$rc ${out:+($(printf '%s' "$out" | tail -1))}"
    fails=$((fails + 1))
  fi
}

check "ALERT_LATCH_LIB = the shim itself (the fleet's own crash-loop spelling)" "$SHIM"
check "ALERT_LATCH_LIB = the shim via a dot-dot detour"                         "$HERE/../lib/alert-latch.sh"
check "ALERT_LATCH_LIB = the shim via a trailing /."                            "$HERE/./alert-latch.sh"

# The legitimate override must still work: pointing at a real library that is
# NOT this shim has to be honoured, or the guard above has eaten the feature.
STUB="$(mktemp -d)"; trap 'rm -rf "$STUB"' EXIT
printf '%s\n' 'notify_and_latch() { :; }' 'ALERT_LATCH_STUB_LOADED=1' >"$STUB/lib.sh"
if out="$(ALERT_LATCH_LIB="$STUB/lib.sh" timeout 20 bash -c \
    'set -uo pipefail; . "$1"; [ "${ALERT_LATCH_STUB_LOADED:-}" = 1 ]' _ "$SHIM" 2>&1)"; then
  echo "ok   — a genuine ALERT_LATCH_LIB override is still honoured"
else
  echo "FAIL — a genuine ALERT_LATCH_LIB override was ignored: $out"
  fails=$((fails + 1))
fi

# And the plain, un-overridden source — every in-repo call site's spelling.
if timeout 20 bash -c 'set -uo pipefail; . "$1"; declare -F notify_and_latch >/dev/null' _ "$SHIM" >/dev/null 2>&1; then
  echo "ok   — plain source with ALERT_LATCH_LIB unset"
else
  echo "FAIL — plain source with ALERT_LATCH_LIB unset"
  fails=$((fails + 1))
fi

if [ "$fails" -ne 0 ]; then
  echo "alert-latch-self-source: $fails FAILED"
  exit 1
fi
echo "alert-latch-self-source: all passed"
