#!/usr/bin/env bash
# alert-latch.sh — thin shim sourcing the shared implementation in donefile's
# scripts/lib/alert-latch.sh (bt-ea85 consolidation, mirrors ff-sync-checkout-lib.sh's
# ce-4f1c pattern) — that file has the full why/how and every function. Kept
# as a real file here (not deleted) so existing
# `source "$(dirname ...)/lib/alert-latch.sh"` call sites in this repo's own
# scripts keep working unchanged.
#
# ma-87e0: this shim had the same latent self-source bug ma-405f fixed in
# meniapp's copy (a caller that pre-sets ALERT_LATCH_LIB to this file's own
# path, then sources it, makes `${ALERT_LATCH_LIB:-...}` find itself already
# set and recurse until bash SIGSEGVs — five meniapp cron guards did exactly
# that for five days straight). No caller here does that yet, but the shape
# is fleet-standard, so the guard goes in before one does. Comparing resolved
# paths (not literal strings) is what makes it hold through a worktree's
# symlinked root and a `..`/`/.` spelling.
_ALERT_LATCH_SELF="${BASH_SOURCE[0]}"
ALERT_LATCH_LIB="${ALERT_LATCH_LIB:-/home/omri/projects/donefile/scripts/lib/alert-latch.sh}"
if [ "$(readlink -f "$ALERT_LATCH_LIB" 2>/dev/null || echo "$ALERT_LATCH_LIB")" \
   = "$(readlink -f "$_ALERT_LATCH_SELF" 2>/dev/null || echo "$_ALERT_LATCH_SELF")" ]; then
  ALERT_LATCH_LIB="/home/omri/projects/donefile/scripts/lib/alert-latch.sh"
fi
source "$ALERT_LATCH_LIB"
