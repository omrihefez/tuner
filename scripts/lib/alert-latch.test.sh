#!/usr/bin/env bash
# alert-latch.test.sh — thin shim running the shared test suite in donefile's
# scripts/lib/alert-latch.test.sh (bt-ea85). Kept as a real file here (not
# deleted) so this repo's own test tooling that globs scripts/lib/*.test.sh
# still picks it up unchanged.
set -uo pipefail
ALERT_LATCH_TEST="${ALERT_LATCH_TEST:-/home/omri/projects/donefile/scripts/lib/alert-latch.test.sh}"
exec bash "$ALERT_LATCH_TEST"
