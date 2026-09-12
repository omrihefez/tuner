#!/usr/bin/env bash
# crontab-install-lock.vendored.sh (ce-4d49) — PINNED CI FALLBACK, NOT THE
# CANONICAL SOURCE. Same defect and same remedy as alert-latch.vendored.sh /
# ff-sync-checkout-lib.vendored.sh: scripts/lib/crontab-install-lock.sh
# sources meniapp's canonical copy by absolute path,
# /home/omri/projects/meniapp/scripts/lib/crontab-install-lock.sh, which
# exists on Omri's box and never on a hosted CI runner. The source then
# fails and crontab_install_take_lock is missing entirely.
#
# The consumer falls back to this file only when the canonical path is
# absent, so a local run still sources the live canonical copy and picks up
# fixes immediately; CI degrades to this snapshot.
#
# Manually synced, and WILL drift if meniapp's copy changes and nobody
# re-copies it. Re-sync with:
#   cp /home/omri/projects/meniapp/scripts/lib/crontab-install-lock.sh \
#      scripts/lib/crontab-install-lock.vendored.sh
#
# --- verbatim copy of meniapp's scripts/lib/crontab-install-lock.sh below ---

crontab_install_take_lock() {
  CRONTAB_LOCK="${CRONTAB_INSTALL_LOCK_FILE:-$HOME/.local/share/meni-hub/crontab-install.lock}"
  mkdir -p "$(dirname "$CRONTAB_LOCK")"
  exec 200>"$CRONTAB_LOCK"
  flock -x 200
}
