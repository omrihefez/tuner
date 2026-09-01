#!/usr/bin/env bash
# ff-sync-main-checkout.sh — fast-forwards bass-tuner's shared main checkout
# (/home/omri/projects/bass-tuner) onto whatever origin/main actually is
# (bt-31a9).
#
# WHY THIS EXISTS. bass-tuner's 5 monitoring crons (scripts/run-monitor.sh
# fallback-cert/domain-audit/heartbeat/stale-deploy/cert-renewal, installed by
# scripts/install-monitoring-crons.sh and scripts/install-cert-renewal-cron.sh)
# all `cd` into and run scripts straight out of THIS checkout's working tree —
# there is no build step and no deploy trigger reading origin/main, so
# whatever is on disk here is what actually runs. This repo's worktree_guard
# means every real change comes from a linked worktree via
# `git push origin <branch>:main`, which never touches this checkout at all.
# A merge lands on origin/main and the board says the task is done, while this
# checkout — and therefore every monitoring cron — keeps running whatever it
# had checked out before, silently, because the job still exits 0. Modeled
# directly on house-control's scripts/ff-sync-main-checkout.sh (hc-498b),
# donefile's (dn-05e3) and tik-api's (tk-66aa), the same gap closed the same
# way there; adapted for this repo's default branch being `main`, not
# `master`.
#
# THE FIX. Key the sync off the remote ref instead of any one cron's
# schedule: on a cron tick, fetch origin/main and, if it has moved past this
# checkout's HEAD, fast-forward onto it with a REAL `git merge --ff-only` —
# not a reset, not a rebase. Deliberately never rebase/reset here: both
# rewrite history in ways a concurrent `git worktree` checkout of this same
# repo could not tolerate, and --ff-only is simply the operation that can
# never discard work.
#
# SAFE BY CONSTRUCTION: `merge --ff-only` NEVER creates a commit (a pure ref
# move), so it can never trip the worktree_guard pre-commit gate, and it
# refuses outright — never forces — if this checkout has diverged from
# origin/main (an unpushed bookkeeping commit made directly here, which
# worktree_guard exempts). A refusal just means next tick tries again;
# nothing here ever discards work. It also refuses if uncommitted local
# changes conflict with the incoming range, which just defers a tick.
set -uo pipefail

# Scrub inherited git plumbing env before ANY git call below (sb-f539).
# GIT_DIR OUTRANKS a `cd` into REPO_ROOT -- an ambient GIT_DIR/GIT_WORK_TREE
# (git exports these into every hook and every process it spawns) would make
# every `git` call below operate on a DIFFERENT repo than the one this script
# just cd'd into, silently. Same class and same fix as sb-7d11
# (install-prune-cron.sh, 52897e1), trips-hub's th-cf17, and second-brain's
# sb-be37 (153b522).
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY \
  GIT_ALTERNATE_OBJECT_DIRECTORIES

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_DIR="${FF_SYNC_STATE_DIR:-$HOME/.local/share/meni-hub/ff-sync-bass-tuner-main-checkout}"
NOTIFY="${MENI_NOTIFY_BIN:-$HOME/meni/bin/meni-notify}"
LAST_ALERT_F="$STATE_DIR/last-alert"
FAIL_COUNT_F="$STATE_DIR/fail-count"
# Alert only after repeated consecutive failures, not the first one — a
# single tick can lose a race against an unrelated concurrent `git commit` in
# this checkout (a momentary .git/index.lock, or a bookkeeping commit
# mid-write) with no real problem behind it; that resolves itself next tick.
ALERT_AFTER_N="${FF_SYNC_ALERT_AFTER_N:-3}"

mkdir -p "$STATE_DIR"

log() { printf '%s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" >&2; }

record_failure() {
  local key="$1" msg="$2" n
  n=$(( $(cat "$FAIL_COUNT_F" 2>/dev/null || echo 0) + 1 ))
  echo "$n" > "$FAIL_COUNT_F"
  if (( n < ALERT_AFTER_N )); then
    log "$msg (failure $n/$ALERT_AFTER_N — not alerting yet)"
    return 0
  fi
  local marked
  marked="$(cat "$LAST_ALERT_F" 2>/dev/null || true)"
  if [ "$marked" != "$key" ]; then
    printf '%s' "$key" > "$LAST_ALERT_F"
    "$NOTIFY" "$msg" 2>/dev/null || true
  fi
  log "$msg (failure $n/$ALERT_AFTER_N)"
}

clear_failure() {
  rm -f "$FAIL_COUNT_F" "$LAST_ALERT_F"
}

# Serialize against a concurrent tick of THIS script (a slow fetch, e.g.).
LOCK_F="$STATE_DIR/sync.lock"
exec 8>"$LOCK_F"
if ! flock -n 8; then
  log "another sync tick is already running — skipping"
  exit 0
fi

cd "$REPO_ROOT" || exit 1

branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '')"
if [ "$branch" != "main" ]; then
  log "HEAD is on '$branch', not main — leaving alone (someone has this checkout mid-use)"
  exit 0
fi

if ! git fetch --quiet origin main; then
  record_failure "fetch-failed" "⚠️ ff-sync-bass-tuner-main-checkout: git fetch origin main has failed $ALERT_AFTER_N+ ticks in a row in $REPO_ROOT — the monitoring crons (fallback-cert/domain-audit/heartbeat/stale-deploy/cert-renewal) cannot see new commits on origin/main until this resolves."
  exit 1
fi

local_sha="$(git rev-parse HEAD)"
remote_sha="$(git rev-parse origin/main)"

if [ "$local_sha" = "$remote_sha" ]; then
  clear_failure
  # Heartbeat on the HEALTHY path, deliberately (mirrors ma-5896): without a
  # line here, a DEAD ff-sync and a healthy in-sync one both write nothing,
  # so silence carries two opposite meanings. This makes liveness positive
  # evidence rather than an absence.
  log "in sync at $local_sha"
  exit 0
fi

if git merge-base --is-ancestor origin/main HEAD 2>/dev/null; then
  # Local is ahead (an unpushed bookkeeping commit, most likely) — nothing to
  # fast-forward, and nothing to force.
  clear_failure
  exit 0
fi

if ! git merge-base --is-ancestor HEAD origin/main 2>/dev/null; then
  record_failure "diverged:$local_sha:$remote_sha" \
    "⚠️ ff-sync-bass-tuner-main-checkout: $REPO_ROOT has DIVERGED from origin/main ($local_sha vs $remote_sha) for $ALERT_AFTER_N+ ticks — refusing to force a fast-forward. Needs a human to look (rebase or reset by hand); the monitoring crons stay stale until this checkout is back in line."
  exit 1
fi

log "origin/main moved $local_sha -> $remote_sha — fast-forwarding"
if git merge --quiet --ff-only origin/main; then
  clear_failure
  log "fast-forwarded to $remote_sha"
  exit 0
fi

record_failure "ff-failed:$local_sha:$remote_sha" \
  "⚠️ ff-sync-bass-tuner-main-checkout: git merge --ff-only origin/main has FAILED $ALERT_AFTER_N+ ticks in a row in $REPO_ROOT ($local_sha -> $remote_sha) even though it looks like a clean fast-forward — likely local uncommitted changes conflicting with the incoming range. Needs a human; the monitoring crons stay stale until this resolves."
exit 1
