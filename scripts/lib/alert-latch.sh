#!/usr/bin/env bash
# alert-latch.sh — thin shim sourcing the shared implementation in donefile's
# scripts/lib/alert-latch.sh (bt-ea85 consolidation, mirrors ff-sync-checkout-lib.sh's
# ce-4f1c pattern) — that file has the full why/how and every function. Kept
# as a real file here (not deleted) so existing
# `source "$(dirname ...)/lib/alert-latch.sh"` call sites in this repo's own
# scripts keep working unchanged.
#
# bt-7727: the absolute path below only exists on Omri's own box. A hosted
# CI runner (ubuntu-latest, .github/workflows/ci.yml) checks out this repo
# alone, so that path is never there, and `source` failed every push since
# at least 2026-10-10 — this repo was the only one of five alert-latch
# consumers with no fallback for it. Falls back to a vendored pinned copy
# (alert-latch.vendored.sh) ONLY when the canonical absolute path is
# missing, so this still sources the live canonical file everywhere that
# file exists (same shape trips-hub/meniapp/meni-arch/house-control already
# carry) and degrades to the pinned copy only where it structurally cannot.
#
# ALERT_LATCH_CANONICAL overrides what counts as "the canonical path" for a
# test that wants to simulate it being absent without touching the real file
# on Omri's box — see alert-latch-ci-fallback.test.sh. No production caller
# sets it; the default below is unchanged from before this fix.
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
_ALERT_LATCH_DEFAULT="${ALERT_LATCH_CANONICAL:-/home/omri/projects/donefile/scripts/lib/alert-latch.sh}"
[ -f "$_ALERT_LATCH_DEFAULT" ] || _ALERT_LATCH_DEFAULT="$(dirname "${BASH_SOURCE[0]}")/alert-latch.vendored.sh"
ALERT_LATCH_LIB="${ALERT_LATCH_LIB:-$_ALERT_LATCH_DEFAULT}"
if [ "$(readlink -f "$ALERT_LATCH_LIB" 2>/dev/null || echo "$ALERT_LATCH_LIB")" \
   = "$(readlink -f "$_ALERT_LATCH_SELF" 2>/dev/null || echo "$_ALERT_LATCH_SELF")" ]; then
  ALERT_LATCH_LIB="$_ALERT_LATCH_DEFAULT"
fi
source "$ALERT_LATCH_LIB"
