#!/usr/bin/env bash
# Vendored from meniapp/scripts/check-crontab-drift.sh (ma-09c1), generalized
# there so each repo that installs its own managed crontab block carries its
# own copy — same convention as lint-crontab-logdirs.sh. Re-sync by copying
# meniapp's version and re-applying the defaults below if it changes.
#
# Detects when the live wildcard-cert-renewal crontab block (installed by
# scripts/install-cert-renewal-cron.sh, between the BEGIN/END guards) has
# drifted from that installer's own $CRON_LINES — its --print-line output is
# the source of truth, so there is exactly one place this block is defined,
# not a second tracked data file that could itself drift out of sync.
#
# Same gap this closes for meniapp already existed here with no equivalent:
# a hand `crontab -e` edit, or a repo edit that never got re-synced onto this
# box, could silently unschedule the wildcard cert renewal — the exact
# failure class that let the cert expire silently for over a month (bt-03ea).
#
# Usage:
#   scripts/check-crontab-drift.sh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BLOCK_LABEL="${BLOCK_LABEL:-wildcard-cert-renewal}"
STATE_DIR="${STATE_DIR:-$HOME/.local/share/meni-hub/${BLOCK_LABEL}-crontab-drift}"
AUDIT_LOG="$STATE_DIR/drift-audit.log"
LAST_ALERT_FILE="$STATE_DIR/last-alerted-diff.sha256"
NOTIFY="$HOME/meni/bin/meni-notify"
CRONTAB_CMD="${CRONTAB_CMD:-crontab}"
CRON_BLOCK="${CRON_BLOCK:-}"
# The block's source of truth is install-cert-renewal-cron.sh's own
# $CRON_LINES (a bash var), not a separate tracked data file — asking the
# installer to print it keeps there being exactly one definition.
EXPECTED_CONTENT_CMD="${EXPECTED_CONTENT_CMD:-$REPO_ROOT/scripts/install-cert-renewal-cron.sh --print-line}"

BEGIN_MARK="${BEGIN_MARK:-# BEGIN wildcard-cert-renewal (scripts/install-cert-renewal-cron.sh)}"
END_MARK="${END_MARK:-# END wildcard-cert-renewal (scripts/install-cert-renewal-cron.sh)}"
INSTALLER_HINT="${INSTALLER_HINT:-scripts/install-cert-renewal-cron.sh}"

mkdir -p "$STATE_DIR"

log() {
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) $*" | tee -a "$AUDIT_LOG" >&2
}

CURRENT_CRON="$("$CRONTAB_CMD" -l 2>/dev/null || true)"
# "|" (not "/") as the sed address delimiter — the marker strings themselves
# contain "/" (script paths), same technique the installer uses.
LIVE_BLOCK="$(printf '%s\n' "$CURRENT_CRON" | sed -n "\|^$BEGIN_MARK\$|,\|^$END_MARK\$|p")"

if [[ -z "$LIVE_BLOCK" ]]; then
  MSG="⚠️ $BLOCK_LABEL crontab: the managed block ($BEGIN_MARK) is missing from the live crontab entirely — run $INSTALLER_HINT to install it"
  if [[ "$(cat "$LAST_ALERT_FILE" 2>/dev/null || true)" != "missing" ]]; then
    log "$MSG"
    "$NOTIFY" "$MSG" 2>/dev/null || true
    echo "missing" > "$LAST_ALERT_FILE"
  else
    log "block still missing (already alerted, not re-notifying)"
  fi
  exit 1
fi

# Strip the marker lines themselves so what's left is directly comparable to
# the tracked source (which the installer wraps verbatim between them).
LIVE_CONTENT="$(printf '%s\n' "$LIVE_BLOCK" | sed '1d;$d')"
if [[ -n "$EXPECTED_CONTENT_CMD" ]]; then
  REPO_CONTENT="$(eval "$EXPECTED_CONTENT_CMD")"
  SOURCE_DESC="$EXPECTED_CONTENT_CMD"
else
  REPO_CONTENT="$(cat "$CRON_BLOCK")"
  SOURCE_DESC="$CRON_BLOCK"
fi

if [[ "$LIVE_CONTENT" == "$REPO_CONTENT" ]]; then
  log "clean: live crontab block matches $SOURCE_DESC"
  rm -f "$LAST_ALERT_FILE"
  exit 0
fi

DIFF_OUTPUT="$(diff <(printf '%s\n' "$LIVE_CONTENT") <(printf '%s\n' "$REPO_CONTENT") || true)"
DIFF_HASH="$(printf '%s' "$DIFF_OUTPUT" | sha256sum | cut -d' ' -f1)"

log "DRIFT detected: live crontab block differs from $SOURCE_DESC"
log "$DIFF_OUTPUT"

if [[ "$(cat "$LAST_ALERT_FILE" 2>/dev/null || true)" == "$DIFF_HASH" ]]; then
  log "already alerted for this exact diff, not re-notifying"
  exit 1
fi

"$NOTIFY" "⚠️ $BLOCK_LABEL crontab drift: live crontab differs from $SOURCE_DESC — see $AUDIT_LOG. Re-run $INSTALLER_HINT after reconciling." \
  2>/dev/null || true
echo "$DIFF_HASH" > "$LAST_ALERT_FILE"
exit 1
