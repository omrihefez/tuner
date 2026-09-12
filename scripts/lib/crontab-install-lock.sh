#!/usr/bin/env bash
# crontab-install-lock.sh — shim sourcing the shared implementation in
# meniapp's scripts/lib/crontab-install-lock.sh (ce-4d49 consolidation,
# mirrors alert-latch.sh's bt-ea85 pattern and ff-sync-checkout-lib.sh's
# ce-4f1c one). Kept as a real file here (not a symlink) so existing
# `source ".../lib/crontab-install-lock.sh"` call sites in this repo's own
# installers keep working unchanged.
#
# ma-9555-class: the absolute path below only exists on Omri's own box. A
# hosted CI runner checks out this repo alone, so that path is never there —
# falls back to a vendored pinned copy (crontab-install-lock.vendored.sh)
# ONLY when the canonical absolute path is missing, so this still sources the
# live canonical file everywhere that file exists and degrades to the pinned
# copy only where it structurally cannot.
_CRONTAB_INSTALL_LOCK_DEFAULT="/home/omri/projects/meniapp/scripts/lib/crontab-install-lock.sh"
[ -f "$_CRONTAB_INSTALL_LOCK_DEFAULT" ] || _CRONTAB_INSTALL_LOCK_DEFAULT="$(dirname "${BASH_SOURCE[0]}")/crontab-install-lock.vendored.sh"
CRONTAB_INSTALL_LOCK_LIB="${CRONTAB_INSTALL_LOCK_LIB:-$_CRONTAB_INSTALL_LOCK_DEFAULT}"
source "$CRONTAB_INSTALL_LOCK_LIB"
