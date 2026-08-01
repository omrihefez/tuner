#!/usr/bin/env bash
# Self-test for bt-a942 (extended by bt-b542): proves the fallback-cert /
# domain-audit / cert-renewal / heartbeat monitors are (a) actually scheduled
# and (b) actually alert to ~/inbox on failure -- not just that the scripts
# exist.
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

# --- 4. check-monitor-heartbeats.sh (bt-b542): stale / missing / unknown
#        monitors are reported, and running it through the real run-monitor.sh
#        wrapper with a fully sandboxed HOME produces the same "-selftest"
#        inbox alert as every other monitor above -- proving the monitor of
#        monitors fails as visibly as anything it watches. The sandboxed HOME
#        also has no ~/meni/bin/meni-notify, so the script's own direct
#        meni-notify call harmlessly no-ops here instead of firing a real
#        alert to the app on every re-run.
mkdir -p "$TMP/hbhome/.cache" "$TMP/hbhome/inbox"
cat > "$TMP/hbhome/.cache/bass-tuner-fallback-cert.log" <<EOF
=== fallback-cert $(date -d '10 days ago' -Is) ===
OK     composer.omrihefez.com -> 404
exit 0
EOF
cat > "$TMP/hbhome/.cache/bass-tuner-domain-audit.log" <<EOF
=== domain-audit $(date -Is) ===
OK     bass.omrihefez.com -> 200
exit 0
EOF
# cert-renewal: no log at all -- simulates "never ran"

hb_out="$(env HOME="$TMP/hbhome" "$REPO/scripts/check-monitor-heartbeats.sh" fallback-cert domain-audit cert-renewal 2>&1)"
hb_code=$?
if [[ "$hb_code" -eq 0 ]]; then
  echo "FAIL   check-monitor-heartbeats.sh: exited 0 with a stale and a missing monitor present"
  FAIL=1
elif ! grep -q "STALE.*fallback-cert" <<<"$hb_out" || ! grep -q "STALE.*cert-renewal" <<<"$hb_out" || ! grep -q "OK.*domain-audit" <<<"$hb_out"; then
  echo "FAIL   check-monitor-heartbeats.sh: unexpected output for stale/missing/fresh mix:"
  echo "$hb_out" | sed 's/^/         /'
  FAIL=1
else
  echo "OK     check-monitor-heartbeats.sh: flags stale fallback-cert + missing cert-renewal, leaves fresh domain-audit alone"
fi

unk_out="$(env HOME="$TMP/hbhome" "$REPO/scripts/check-monitor-heartbeats.sh" nonexistent-bt-b542-selftest 2>&1)"
unk_code=$?
if [[ "$unk_code" -eq 0 ]] || ! grep -q "UNKNOWN" <<<"$unk_out"; then
  echo "FAIL   check-monitor-heartbeats.sh: unknown monitor name not reported (got: $unk_out)"
  FAIL=1
else
  echo "OK     check-monitor-heartbeats.sh: unknown monitor name reported, not silently skipped"
fi

hb_inbox="$TMP/hbhome/inbox/bass-tuner-heartbeat-selftest-${DATE}.md"
rm -f "$hb_inbox"
env HOME="$TMP/hbhome" "$RUNNER" heartbeat-selftest "$REPO/scripts/check-monitor-heartbeats.sh" fallback-cert >/dev/null 2>&1
rm_code=$?
if [[ "$rm_code" -eq 0 ]]; then
  echo "FAIL   check-monitor-heartbeats.sh via run-monitor.sh: exited 0, expected non-zero"
  FAIL=1
elif [[ ! -f "$hb_inbox" ]]; then
  echo "FAIL   check-monitor-heartbeats.sh via run-monitor.sh: exited $rm_code but no $hb_inbox written"
  FAIL=1
else
  echo "OK     check-monitor-heartbeats.sh via run-monitor.sh: exit $rm_code -> $hb_inbox"
fi

# --- 5. all four are actually on the crontab, not just present on disk ---
CRON="$(crontab -l 2>/dev/null || true)"
for pat in "check-fallback-cert.sh" "audit-domains.sh" "renew-wildcard-cert.sh" "check-monitor-heartbeats.sh"; do
  if echo "$CRON" | grep -q "$pat"; then
    echo "OK     $pat is scheduled in crontab"
  else
    echo "FAIL   $pat missing from crontab"
    FAIL=1
  fi
done

# --- 6. the tracked installer would REINSTALL every monitor it manages
#        (bt-34af). install-monitoring-crons.sh replaces its managed block
#        wholesale from its own $CRON_LINES, so an entry that is live between
#        the markers but missing from that variable is deleted on the next
#        run -- and a monitor that never runs looks exactly like a monitor
#        whose every check passed. The heartbeat entry was in precisely that
#        state: scheduled live, absent from the installer.
#
#        This reads the installer's own --dry-run output, NOT the live crontab
#        that step 5 checks, so the drift is caught while it is still only a
#        latent bug -- step 5 can only notice after a run has already wiped
#        the entry. --dry-run also exercises the installer's drop guard, which
#        exits non-zero rather than quietly unscheduling anything.
INSTALLER="$REPO/scripts/install-monitoring-crons.sh"
dry_out="$("$INSTALLER" --dry-run 2>&1)"
dry_code=$?
if [[ "$dry_code" -ne 0 ]]; then
  echo "FAIL   install-monitoring-crons.sh --dry-run exited $dry_code (drop guard tripped?):"
  echo "$dry_out" | sed 's/^/         /'
  FAIL=1
else
  dry_block="$(printf '%s\n' "$dry_out" | sed -n '/# BEGIN bass-tuner-monitoring/,/# END bass-tuner-monitoring/p')"
  for pat in "check-fallback-cert.sh" "audit-domains.sh" "check-monitor-heartbeats.sh"; do
    if grep -qF "$pat" <<<"$dry_block"; then
      echo "OK     $pat is in install-monitoring-crons.sh's managed block"
    else
      echo "FAIL   $pat is NOT in install-monitoring-crons.sh's managed block -- the next installer run would unschedule it"
      FAIL=1
    fi
  done
fi

# --- 7. bt-6492: check-heartbeat-liveness.sh (watches check-monitor-
#        heartbeats.sh's OWN liveness) reports absent/stale/fresh correctly,
#        and is installed on a scheduler that is NOT bass-tuner's cron -- the
#        whole point being that a crontab-level failure (crond stopped, the
#        managed block rewritten, run-monitor.sh losing its exec bit) can
#        never also take this check down, the way it could if it lived
#        inside check-monitor-heartbeats.sh or its cron entry.
HB_LIVENESS="$REPO/scripts/check-heartbeat-liveness.sh"
HBTMP="$(mktemp -d)"
mkdir -p "$HBTMP/home/.cache"

absent_out="$(env HOME="$HBTMP/home" MAX_AGE_HOURS=30 "$HB_LIVENESS" 2>&1)"
absent_code=$?
if [[ "$absent_code" -eq 0 ]] || ! grep -q "STALE.*NEVER logged" <<<"$absent_out"; then
  echo "FAIL   check-heartbeat-liveness.sh: absent log not reported (got exit $absent_code: $absent_out)"
  FAIL=1
else
  echo "OK     check-heartbeat-liveness.sh: absent log reported"
fi

cat > "$HBTMP/home/.cache/bass-tuner-heartbeat.log" <<EOF
=== heartbeat $(date -d '40 hours ago' -Is) ===
OK       fallback-cert last ran 0h ago (limit 30h)
exit 0
EOF
stale_out="$(env HOME="$HBTMP/home" MAX_AGE_HOURS=30 "$HB_LIVENESS" 2>&1)"
stale_code=$?
if [[ "$stale_code" -eq 0 ]] || ! grep -q "STALE.*40h ago" <<<"$stale_out"; then
  echo "FAIL   check-heartbeat-liveness.sh: stale (40h) log not reported (got exit $stale_code: $stale_out)"
  FAIL=1
else
  echo "OK     check-heartbeat-liveness.sh: stale (40h > 30h limit) log reported"
fi

cat > "$HBTMP/home/.cache/bass-tuner-heartbeat.log" <<EOF
=== heartbeat $(date -d '1 hour ago' -Is) ===
OK       fallback-cert last ran 0h ago (limit 30h)
exit 0
EOF
fresh_out="$(env HOME="$HBTMP/home" MAX_AGE_HOURS=30 "$HB_LIVENESS" 2>&1)"
fresh_code=$?
if [[ "$fresh_code" -ne 0 ]] || ! grep -q "^OK" <<<"$fresh_out"; then
  echo "FAIL   check-heartbeat-liveness.sh: fresh (1h) log wrongly flagged (got exit $fresh_code: $fresh_out)"
  FAIL=1
else
  echo "OK     check-heartbeat-liveness.sh: fresh (1h < 30h limit) log passes"
fi

rm -rf "$HBTMP"

# The watchdog must never be crontab-scheduled -- it exists precisely because
# that scheduler can silently fail, so if it ever gets added there this
# regresses back to the original bug.
if crontab -l 2>/dev/null | grep -q "check-heartbeat-liveness.sh"; then
  echo "FAIL   check-heartbeat-liveness.sh must NOT be scheduled via crontab (defeats the whole point)"
  FAIL=1
else
  echo "OK     check-heartbeat-liveness.sh is not crontab-scheduled"
fi

if command -v systemctl >/dev/null 2>&1; then
  if systemctl --user is-enabled bass-tuner-heartbeat-watchdog.timer >/dev/null 2>&1 \
     && systemctl --user is-active bass-tuner-heartbeat-watchdog.timer >/dev/null 2>&1; then
    echo "OK     bass-tuner-heartbeat-watchdog.timer is installed, enabled and active (systemd --user, not cron)"
  else
    echo "FAIL   bass-tuner-heartbeat-watchdog.timer is not enabled+active -- run scripts/install-heartbeat-watchdog.sh"
    FAIL=1
  fi
else
  echo "SKIP   systemctl not available in this environment -- cannot verify the timer is installed"
fi

exit "$FAIL"
