#!/usr/bin/env bash
# Self-test for bt-a942: proves the fallback-cert / domain-audit /
# cert-renewal monitors are (a) actually scheduled and (b) actually alert to
# ~/inbox on failure -- not just that the scripts exist.
#
# For (b), each underlying script is forced to fail via a harmless sabotage
# (bad target host, or an unreadable HOME so the secrets file can't be
# found) and run through the real run-monitor.sh wrapper under a "-selftest"
# name so it can never collide with a real scheduled run's inbox file. No
# real Cloudflare/Vercel/DNS state is touched: the sabotaged copies fail
# before any of that happens (renew-wildcard-cert.sh's own FATAL check for
# an unreadable secrets file is the very first thing it does).
#
# Cleans up after itself (temp files, selftest inbox files) so repeated runs
# -- this is meant to be donefile's --test command, re-run on every close --
# don't pile up stale files.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNNER="$REPO/scripts/run-monitor.sh"
DATE="$(date -I)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

FAIL=0

check() {
  local name="$1" desc="$2"
  shift 2
  local inbox="$HOME/inbox/bass-tuner-${name}-${DATE}.md"
  rm -f "$inbox"
  "$RUNNER" "$name" "$@" >/dev/null 2>&1
  local code=$?
  if [[ "$code" -eq 0 ]]; then
    echo "FAIL   $desc: run-monitor exited 0, expected non-zero"
    FAIL=1
    return
  fi
  if [[ ! -f "$inbox" ]]; then
    echo "FAIL   $desc: exited $code but no $inbox written"
    FAIL=1
    return
  fi
  echo "OK     $desc: exit $code -> $inbox"
  rm -f "$inbox"
}

# --- 1. check-fallback-cert.sh, sabotaged to hit a domain that can't 404 ---
sed 's/^HOST=.*/HOST="invalid.invalid.bt-a942-selftest"/' \
  "$REPO/scripts/check-fallback-cert.sh" > "$TMP/check-fallback-cert-fail.sh"
chmod +x "$TMP/check-fallback-cert-fail.sh"
check fallback-cert-selftest "check-fallback-cert.sh (forced failure)" \
  "$TMP/check-fallback-cert-fail.sh"

# --- 2. audit-domains.sh, sabotaged to check a subdomain that isn't a real
#        live app (falls through to CHECK/unexpected-code, not OK) ---
sed 's/^SUBS=.*/SUBS=(nonexistent-bt-a942-selftest)/' \
  "$REPO/scripts/audit-domains.sh" > "$TMP/audit-domains-fail.sh"
chmod +x "$TMP/audit-domains-fail.sh"
check domain-audit-selftest "audit-domains.sh (forced failure)" \
  "$TMP/audit-domains-fail.sh"

# --- 3. renew-wildcard-cert.sh, run with HOME pointed at an empty dir so its
#        own first FATAL check (unreadable ~/meni/secrets/.env) fires before
#        it ever touches Cloudflare or Vercel ---
mkdir -p "$TMP/fakehome"
check cert-renewal-selftest "renew-wildcard-cert.sh (forced failure)" \
  env HOME="$TMP/fakehome" "$REPO/scripts/renew-wildcard-cert.sh"

# --- 4. all three are actually on the crontab, not just present on disk ---
CRON="$(crontab -l 2>/dev/null || true)"
for pat in "check-fallback-cert.sh" "audit-domains.sh" "renew-wildcard-cert.sh"; do
  if echo "$CRON" | grep -q "$pat"; then
    echo "OK     $pat is scheduled in crontab"
  else
    echo "FAIL   $pat missing from crontab"
    FAIL=1
  fi
done

exit "$FAIL"
