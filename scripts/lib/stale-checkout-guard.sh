#!/usr/bin/env bash
# stale-checkout-guard.sh — shim sourcing the shared implementation in
# meniapp's scripts/lib/stale-checkout-guard.sh (ma-2f6d consolidation,
# mirrors crontab-install-lock.sh's ce-4d49 pattern and alert-latch.sh's
# bt-ea85 one). Kept as a real file here (not a symlink) so
# `source ".../lib/stale-checkout-guard.sh"` call sites in this repo's own
# installers keep working unchanged.
#
# ma-9555-class: the absolute path below only exists on Omri's own box. A
# hosted CI runner checks out this repo alone, so that path is never there —
# falls back to a vendored pinned copy (stale-checkout-guard.vendored.sh)
# ONLY when the canonical absolute path is missing, so this still sources the
# live canonical file everywhere that file exists and degrades to the pinned
# copy only where it structurally cannot.
_STALE_CHECKOUT_GUARD_DEFAULT="/home/omri/projects/meniapp/scripts/lib/stale-checkout-guard.sh"
[ -f "$_STALE_CHECKOUT_GUARD_DEFAULT" ] || _STALE_CHECKOUT_GUARD_DEFAULT="$(dirname "${BASH_SOURCE[0]}")/stale-checkout-guard.vendored.sh"
STALE_CHECKOUT_GUARD_LIB="${STALE_CHECKOUT_GUARD_LIB:-$_STALE_CHECKOUT_GUARD_DEFAULT}"
source "$STALE_CHECKOUT_GUARD_LIB"
