#!/usr/bin/env bash
# Regression test for bt-2604: check-monitor-heartbeats.sh's DEFAULT (no-args)
# monitor set must cover every monitor the real installers actually schedule
# -- install-monitoring-crons.sh for everything except cert-renewal, which
# install-cert-renewal-cron.sh schedules on its own separate weekly cadence --
# not a hand-restated subset of it. MAX_AGE_HOURS had already drifted from
# the installers' real monitor set once before this test existed
# (tunnel-liveness/bt-0603) and did so again for permissions-policy
# (bt-40c5/bt-b97b), each added to an installer and running on a real cron
# schedule while staying permanently invisible to this watcher.
#
# Both installers hardcode their own REPO path (not derived from this
# script's location), so their --print-line output can't be sandboxed by
# HOME -- this test queries the REAL installers, which is exactly the point:
# it proves this repo's actual installed monitor set is covered, not a
# fixture standing in for it. Everything else (the fixture logs, the HOME
# this script runs check-monitor-heartbeats.sh against) is fully sandboxed
# in a tempdir and never touches the real crontab or $HOME.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
HEARTBEAT="$HERE/check-monitor-heartbeats.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mapfile -t REAL_MONITOR_NAMES < <(
  { "$REPO/scripts/install-monitoring-crons.sh" --print-line
    "$REPO/scripts/install-cert-renewal-cron.sh" --print-line; } | awk '!/^[[:space:]]*#/ {
    for (i = 1; i < NF; i++)
      if ($i ~ /run-monitor\.sh$/) { print $(i + 1); break }
  }' | sed '/^$/d' | grep -vFx "heartbeat" | sort -u)

if [[ "${#REAL_MONITOR_NAMES[@]}" -eq 0 ]]; then
  echo "FAIL   could not derive any monitor names from the real installers' --print-line -- can't run this test" >&2
  exit 1
fi

mkdir -p "$TMP/.cache"
for mon in "${REAL_MONITOR_NAMES[@]}"; do
  cat > "$TMP/.cache/bass-tuner-${mon}.log" <<EOF
=== $mon $(date -Is) ===
OK
exit 0
EOF
done

out="$(env HOME="$TMP" "$HEARTBEAT" 2>&1)"
code=$?
ok_count="$(grep -c '^OK' <<<"$out" || true)"
expected_count="${#REAL_MONITOR_NAMES[@]}"

if [[ "$code" -ne 0 ]]; then
  echo "FAIL   check-monitor-heartbeats.sh (no args): exited $code against fresh logs for every real installer monitor (${REAL_MONITOR_NAMES[*]}):"
  echo "$out" | sed 's/^/         /'
  exit 1
elif grep -q "UNKNOWN" <<<"$out"; then
  echo "FAIL   check-monitor-heartbeats.sh (no args): reported UNKNOWN against a real installer monitor:"
  echo "$out" | sed 's/^/         /'
  exit 1
elif [[ "$ok_count" -ne "$expected_count" ]]; then
  echo "FAIL   check-monitor-heartbeats.sh (no args): checked $ok_count monitor(s), installers schedule $expected_count (${REAL_MONITOR_NAMES[*]}) -- the default set has drifted from the installers' --print-line output:"
  echo "$out" | sed 's/^/         /'
  exit 1
fi

echo "OK     check-monitor-heartbeats.sh (no args): default monitor set matches all $expected_count of the installers' --print-line monitors (${REAL_MONITOR_NAMES[*]})"
exit 0
