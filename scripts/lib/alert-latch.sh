#!/usr/bin/env bash
# alert-latch.sh — thin shim sourcing the shared implementation in donefile's
# scripts/lib/alert-latch.sh (bt-ea85 consolidation, mirrors ff-sync-checkout-lib.sh's
# ce-4f1c pattern) — that file has the full why/how and every function. Kept
# as a real file here (not deleted) so existing
# `source "$(dirname ...)/lib/alert-latch.sh"` call sites in this repo's own
# scripts keep working unchanged.
ALERT_LATCH_LIB="${ALERT_LATCH_LIB:-/home/omri/projects/donefile/scripts/lib/alert-latch.sh}"
source "$ALERT_LATCH_LIB"
