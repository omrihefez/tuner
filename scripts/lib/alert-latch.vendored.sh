#!/usr/bin/env bash
# alert-latch.vendored.sh (bt-7727) — PINNED CI FALLBACK, NOT THE CANONICAL
# SOURCE. bt-ea85's shim (./alert-latch.sh) sources donefile's canonical copy
# by absolute path, /home/omri/projects/donefile/scripts/lib/alert-latch.sh —
# a path that exists on Omri's box but not on a hosted GitHub Actions runner,
# which checks out this repo alone (.github/workflows/ci.yml: runs-on:
# ubuntu-latest). Every CI "Unit tests" run has been failing on this since at
# least 2026-10-10 — not with "No such file or directory" directly, but one
# level downstream: check-monitor-heartbeats.sh's `. lib/alert-latch.sh ||
# exit 2` traps the missing-source error, so notify_and_latch is never
# defined and never called, and check-heartbeat-alert-dedup.test.sh's first
# case fails "expected 1 notify ... got 0" before the test loop ever reaches
# scripts/lib/alert-latch.test.sh (confirmed on run 38380100889).
#
# This repo was the only one of five alert-latch consumers with no fallback
# for this at all — meniapp, meni-arch, trips-hub and house-control each
# already carry the identical `[ -f ... ] ||` guard and their own pinned
# copy. This file brings bass-tuner in line with that convention rather than
# inventing a new one (bt-7727).
#
# The shim falls back to this file only when the absolute path is missing,
# i.e. only in CI — a local run on Omri's box still sources the real
# canonical copy and picks up fixes immediately.
#
# This file is a manually-synced snapshot (copied verbatim below) and WILL
# drift if donefile's canonical copy changes and nobody re-copies it here —
# that is the tradeoff for CI being able to run this suite at all.
# check-vendored-pin-drift.sh (meniapp, ma-2aba/ma-42bf) watches this file
# against donefile's canonical by function name and alerts on drift; keep
# this pin current rather than relying on that guard to catch staleness late.
# WARNING taken from bt-7727 itself: re-syncing with a bare
# `cp donefile/scripts/lib/alert-latch.sh scripts/lib/alert-latch.vendored.sh`
# OVERWRITES this header along with the body. Splice the canonical's body
# below this header by hand (or script it), never a bare cp.
#
# --- verbatim copy of donefile's scripts/lib/alert-latch.sh starts here ---
# alert-latch.sh — ma-c1b2. The one place a guard is allowed to write its
# "already alerted" latch, and the rule that it may only do so after the alert
# actually landed somewhere Omri can read it.
#
# CANONICAL SOURCE (bt-ea85). This file used to be hand-copied, byte-for-byte,
# into bass-tuner, tik-api, second-brain and trips-hub, plus a fifth,
# independently-extended copy in meniapp (ma-bb87 added notify_and_latch_with_age
# there and nowhere else) — five copies, one already silently ahead of the
# other four. This IS the copy now; every fleet repo's scripts/lib/alert-latch.sh
# is a thin shim that sources this file (mirrors scripts/lib/ff-sync-checkout-lib.sh,
# ce-4f1c). Edit here; scripts/lib/alert-latch-fleet-divergence.test.sh fails if
# a caller's shim reimplements this instead of sourcing it.
#
# THE BUG THIS EXISTS TO KILL. Every alerting guard in scripts/ ended with the
# same two lines — a best-effort notify followed by an UNCONDITIONAL latch
# write. From check-pending-activation.sh, pre-fix:
#
#     [ -x "$NOTIFY" ] && "$NOTIFY" "$msg" >/dev/null 2>&1
#     echo "$fingerprint" > "$LAST_ALERT_FILE"
#
# Two ways the notification never happens, and neither stopped the latch:
#   1. $NOTIFY is not executable — the `&&` short-circuits, nothing is sent,
#      and the next line still records "alerted".
#   2. $NOTIFY runs and FAILS — its exit status is thrown away by
#      `>/dev/null 2>&1`, so a delivery error is indistinguishable from success.
# The `"$NOTIFY" ... 2>/dev/null || true` spelling used by the other half of the
# guards is the same hole with a different mouth: `|| true` swallows a 127
# (binary missing) exactly as thoroughly as the `&&` swallows a short-circuit.
#
# Because the latch is keyed on the offender SET and not on time, the guard then
# never re-announces that same unresolved condition. ONE dropped notification
# silences the check permanently, and silently. Certificate expiry and GitHub
# PAT validity are both in that set.
#
# WHAT "DELIVERED" MEANS HERE, AND WHY EXIT 0 IS THE RIGHT TEST.
# `~/meni/bin/meni-notify` exits 0 only when the hub answered its POST
# /api/announce with 201, or (hub unreachable) Telegram answered 200. A 201
# means hub/src/api.ts's announce handler already ran `store.addMessage(...)`:
# the alert is a DURABLE, unread-bumping message row in Omri's Meni thread — a
# PULL surface he reads on his own schedule, not a notification that has to
# catch him. Every other meni-notify outcome is a non-zero exit (2 = attachment
# refused, 3 = partial, 4 = hub 4xx, 1 = hub unreachable AND telegram failed).
#
# This is the distinction the fix turns on, so it is worth stating plainly:
# Omri's master notification mute (hub_settings.notify_enabled = 0, deliberate
# since ~2026-07-13, and NOT this task's business) is enforced in
# hub/src/push.ts, at PUSH time — `if (!settings.notify_enabled && !breakthrough)`
# refuses the web push. It does not touch the announce row. So a muted channel
# cannot make meni-notify exit 0 on a message that went nowhere: the message is
# still in the app. A latch written on exit 0 is therefore a latch written on a
# condition that reached a surface, never on a push that was deliberately
# swallowed. Nothing here re-enables, widens, or routes around that mute.
#
# THE CONTRACT
#   delivered (exit 0) -> latch is written, and only then
#   anything else      -> latch is left EXACTLY as it was, the reason is logged
#                         on stderr (never swallowed) and recorded in a sibling
#                         <latch>.undelivered file, and the caller's next run
#                         re-attempts the alert.
# A guard that keeps failing to deliver therefore keeps retrying instead of
# going quiet forever. Degrade to DELAYED, never to PERMANENT SILENCE.
#
# Kept as a sourced function rather than copied into each guard for the reason
# the copies existed in the first place: 14 hand-written spellings of the same
# two lines is how a fix reaches nine of them and misses five.

# alert_latch_log <words...>
# All this library's diagnostics go to stderr, where cron captures them. The
# swallowing of a delivery failure is half of the bug being fixed, so nothing
# in here is allowed to be quiet about one.
alert_latch_log() { echo "[alert-latch] $*" >&2; }

# _alert_latch_abs <path-or-bare-command> — best-effort absolute, symlink-
# resolved form, so two different spellings of the same binary (a bare name
# found on PATH vs. its full path, or a path through a symlinked worktree
# root) compare equal. Never fails: falls back to the input unchanged if it
# cannot be resolved (relative path to nothing, PATH miss), which just means
# the comparison in _alert_latch_refuse_if_live_in_test below misses rather
# than false-refuses.
_alert_latch_abs() {
  local p="$1" resolved
  case "$p" in
    */*) resolved="$(readlink -f "$p" 2>/dev/null)" ;;
    *)   resolved="$(command -v "$p" 2>/dev/null)"
         [ -n "$resolved" ] && resolved="$(readlink -f "$resolved" 2>/dev/null)" ;;
  esac
  printf '%s' "${resolved:-$p}"
}

# _alert_latch_real_home — the account home from the password database for
# the user actually running this process, deliberately NOT `$HOME` (which any
# caller, test or otherwise, can and does override for the duration of one
# call). Falls back to `$HOME` only if the password database lookup itself
# is unavailable (e.g. a minimal container with no nsswitch) — a miss there
# just means the live-binary comparison below degrades to the old,
# fakeable-by-$HOME behaviour, never a hard failure.
_alert_latch_real_home() {
  local home
  home="$(getent passwd "$(id -un)" 2>/dev/null | cut -d: -f6)"
  printf '%s' "${home:-$HOME}"
}

# _alert_latch_refuse_if_live_in_test <notify-bin> — ma-9295. The chokepoint
# every notify_and_latch*/notify_now call now passes through before it is
# allowed to touch the real notifier.
#
# RECURRENCE OF ma-1926, TWO MONTHS LATER, IN A SCRIPT WRITTEN AFTER THAT
# SWEEP. ma-1926 swept every scripts/*.test.sh for an un-stubbed NOTIFY and
# found none — and then a brand-new caller (meni-arch's crontab-drift guard
# for ar-2765) got exercised by hand against a tampered fixture, with NOTIFY
# left at its default, and put a false ⚠️ infra alert in front of Omri. A
# sweep is point-in-time; the next un-stubbed caller, formal test or ad-hoc
# verification alike, starts from the exact same unsafe default. Per-test,
# per-author discipline is what already failed twice — this is the fix at the
# chokepoint EVERY caller already passes through, not another sweep.
#
# $NOTIFY is, by design, an opaque path by the time it reaches here — a guard
# script resolves `${NOTIFY:-$HOME/meni/bin/meni-notify}` long before calling
# notify_and_latch, and that resolution is deliberately untouched by this fix
# (ma-9295 must not change what a caller that sets nothing gets, or every cron
# line across the fleet needs auditing). So the only thing this can safely
# act on is comparing the RESOLVED path against the known live binary: if a
# caller running under a declared test marker (MENI_SCRIPT_UNDER_TEST) is
# about to hand that exact binary a message, refuse before the exec — the
# caller forgot to stub NOTIFY, and under the marker that is exactly the
# condition the marker exists to catch.
#
# Outside the marker (MENI_SCRIPT_UNDER_TEST unset — true of every crontab
# line on this box today, since nothing sets it), this function always
# returns 0 immediately and touches nothing: production delivery is
# byte-for-byte unchanged by this fix.
#
# MUST NOT compare against the CURRENT $HOME. check-crontab-drift.test.sh
# (and its siblings) already establish a working, hermetic pattern for this
# exact family of guards: fake $HOME for the duration of the call so the
# script's own `${NOTIFY:-$HOME/meni/bin/meni-notify}` default resolves to a
# stub planted at $FAKE_HOME/meni/bin/meni-notify, rather than overriding
# NOTIFY directly. That stub lives at the SAME relative path the real one
# does — only $HOME differs — so comparing against the caller's current $HOME
# makes a properly-faked, already-safe test indistinguishable from a caller
# that truly forgot, and refuses the former (measured: turning this marker on
# for scripts/check-crontab-drift.test.sh with a naive $HOME-relative default
# broke 5 of its passing cases outright). The REAL account home — independent
# of whatever $HOME has been set to for this process — is what actually
# identifies the one true live binary; _alert_latch_real_home below reads
# that from the password database, not the environment.
#
# MENI_LIVE_NOTIFY_BIN overrides what counts as "the live binary" (default
# <real-home>/meni/bin/meni-notify) for a test that wants to point the
# comparison at a fixture explicitly instead.
#
#   returns 0 — safe to proceed (no marker, or $notify is not the live binary).
#   returns 1 — REFUSED: marker is set and $notify IS the live binary.
_alert_latch_refuse_if_live_in_test() {
  local notify="${1:-}"
  [ -n "${MENI_SCRIPT_UNDER_TEST:-}" ] || return 0
  [ -n "$notify" ] || return 0
  local live="${MENI_LIVE_NOTIFY_BIN:-$(_alert_latch_real_home)/meni/bin/meni-notify}"
  if [ "$(_alert_latch_abs "$notify")" = "$(_alert_latch_abs "$live")" ]; then
    alert_latch_log "FATAL: refusing to call the LIVE notifier ($notify) while" \
      "MENI_SCRIPT_UNDER_TEST=1 is set. This run would otherwise have sent a" \
      "REAL alert to Omri. Stub NOTIFY (point it at a recorder) before" \
      "exercising this guard, or unset MENI_SCRIPT_UNDER_TEST if this really" \
      "is a live run."
    return 1
  fi
  return 0
}

# _alert_latch_record_failure <undelivered-file> <latch-value> <reason> <notifier-output>
# Durable, machine-greppable breadcrumb for a delivery that did not happen, so
# the failure survives log rotation and is inspectable after the fact (`cat
# <state-dir>/*.undelivered`). Best-effort: a state dir we cannot write is
# already reported by the caller, and must never turn a failed delivery into a
# hard error that changes the guard's exit code.
_alert_latch_record_failure() {
  local file="$1" value="$2" reason="$3" out="$4" dir
  dir="$(dirname "$file")"
  mkdir -p "$dir" 2>/dev/null || return 0
  {
    printf 'at\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
    printf 'reason\t%s\n' "$reason"
    printf 'latch_value_withheld\t%s\n' "$value"
    printf 'notifier_output\t%s\n' "$(printf '%s' "$out" | tr '\n' ' ')"
  } >"$file" 2>/dev/null || true
}

# _alert_latch_write <latch-file> <value>
# Atomic (write-temp + rename within the same directory) so a guard killed
# mid-write can never leave a truncated latch that reads as a DIFFERENT
# offender set and re-alerts, or as a matching one and suppresses.
# Returns non-zero if the latch could not be written.
_alert_latch_write() {
  local file="$1" value="$2" dir tmp
  dir="$(dirname "$file")"
  mkdir -p "$dir" || return 1
  tmp="$(mktemp "$dir/.alert-latch.XXXXXX" 2>/dev/null)" || return 1
  printf '%s\n' "$value" >"$tmp" || { rm -f "$tmp"; return 1; }
  mv -f "$tmp" "$file" || { rm -f "$tmp"; return 1; }
  return 0
}

# notify_and_latch <notify-bin> <latch-file> <latch-value> <message>
#
# Sends <message> via <notify-bin> and writes <latch-value> into <latch-file>
# IF AND ONLY IF the send actually happened and exited 0.
#
#   returns 0 — delivered AND latched. The caller may treat this condition as
#               announced; the next run with the same <latch-value> stays quiet.
#   returns 1 — NOT delivered. <latch-file> is untouched (it is not created, and
#               an existing one is not modified), so the next run alerts again.
#   returns 2 — caller bug (missing arguments). Also leaves the latch untouched.
#
# A missing or non-executable notifier is case 1, deliberately: "I had nothing
# to send it with" is a delivery failure, not "nothing to do". That was hole #1
# above, and it is the one that fires on a fresh box or a bad $PATH.
#
# ERREXIT. Some callers (meniapp's check-crontab-drift.sh; trips-hub's and
# meniapp's check-vercel-git-disconnected.sh did too, until ma-18ea dropped
# errexit there so its blind paths could reach a notifier instead of aborting
# into a traceback) run under `set -euo pipefail`. Without the save/disable/
# restore below, the very
# first thing this function does on a failed delivery —
# `out="$("$notify" ...)"` with a non-zero status — would abort the CALLER
# outright, before a single word of diagnosis was printed. That is the bug being
# fixed wearing a different hat: the delivery failure would once again be
# invisible. `local -` is NOT usable for this; measured on bash 5.2.21, it does
# not restore errexit on return.
notify_and_latch() {
  local _al_errexit=0
  case $- in *e*) _al_errexit=1 ;; esac
  set +e
  _notify_and_latch_impl "$@"
  local _al_rc=$?
  [ "$_al_errexit" -eq 1 ] && set -e
  return "$_al_rc"
}

# _notify_and_latch_impl — the body of notify_and_latch, always running with
# errexit off. Call notify_and_latch, never this.
_notify_and_latch_impl() {
  local notify="${1:-}" latch="${2:-}" value="${3:-}" msg="${4:-}"

  if [ -z "$latch" ] || [ -z "$msg" ]; then
    alert_latch_log "BUG: notify_and_latch needs <notify-bin> <latch-file> <latch-value> <message>"
    return 2
  fi

  local undelivered="${latch}.undelivered"

  if ! _alert_latch_refuse_if_live_in_test "$notify"; then
    _alert_latch_record_failure "$undelivered" "$value" "refused-live-notifier-in-test:$notify" ""
    return 1
  fi

  if [ -z "$notify" ] || [ ! -x "$notify" ]; then
    alert_latch_log "NOT DELIVERED: notifier missing or not executable: ${notify:-<unset>}." \
      "Latch NOT written — the next run will alert again. Message was: $msg"
    _alert_latch_record_failure "$undelivered" "$value" "notifier-not-executable:${notify:-<unset>}" ""
    return 1
  fi

  # stdout AND stderr are captured rather than discarded: meni-notify explains
  # itself on failure ("hub unreachable", "REFUSED by hub (4xx)", "FAILED on
  # both hub and telegram") and that explanation is the whole diagnostic. On
  # success it is chatter and gets dropped.
  local out rc
  out="$("$notify" "$msg" 2>&1)"
  rc=$?

  if [ "$rc" -ne 0 ]; then
    alert_latch_log "NOT DELIVERED: $notify exited $rc." \
      "Latch NOT written — the next run will alert again. Notifier said: ${out:-<no output>}"
    _alert_latch_record_failure "$undelivered" "$value" "notifier-exit-$rc" "$out"
    return 1
  fi

  if ! _alert_latch_write "$latch" "$value"; then
    # Delivered, but we cannot remember that we did. Say so: the alternative is
    # re-announcing the same condition every tick with no explanation.
    alert_latch_log "DELIVERED, but could NOT write the latch at $latch —" \
      "this condition will be re-announced on every run until that path is writable."
    return 1
  fi

  rm -f "$undelivered" 2>/dev/null || true
  return 0
}

# notify_and_latch_with_age <notify-bin> <latch-file> <latch-value> <realert-interval-secs> <message>
#
# ma-bb87. The age-aware half of the same rule: an alert that RE-FIRES while
# the condition stands, instead of latching once and going quiet forever no
# matter how long the fault persists. Two sites hand-rolled this before this
# function existed — check-plugin-install-drift.sh (ma-29d7) and
# deploy-app-if-changed.sh's notify_once (ma-86c2 follow-up) — and both had to
# separately rediscover the same trap: a SINGLE refreshed latch file resets the
# clock on every re-alert, so the message reports the re-alert INTERVAL forever
# while calling it the TOTAL age. The fix both arrived at independently is the
# two-file split kept here — <latch-file> holds the current condition's
# identity and its mtime is when that identity was FIRST seen; a sibling
# <latch-file>.last holds when it was last SPOKEN about. Only .last advances on
# a re-alert, so the age reported always grows from the true first sighting.
#
#   returns 0 — delivered: either a fresh alert (new/changed <latch-value>) or
#               a re-alert (same value, standing longer than <realert-interval-secs>).
#   returns 1 — NOT delivered. Nothing on disk changes — the caller's next run
#               re-attempts, same as notify_and_latch.
#   returns 2 — caller bug (missing arguments).
#   returns 3 — suppressed: same <latch-value> as last time, and still within
#               <realert-interval-secs> of the last alert. Nothing sent, nothing
#               written — this is the ordinary quiet tick, not a failure.
notify_and_latch_with_age() {
  local _al_errexit=0
  case $- in *e*) _al_errexit=1 ;; esac
  set +e
  _notify_and_latch_with_age_impl "$@"
  local _al_rc=$?
  [ "$_al_errexit" -eq 1 ] && set -e
  return "$_al_rc"
}

_notify_and_latch_with_age_impl() {
  local notify="${1:-}" latch="${2:-}" value="${3:-}" interval="${4:-}" msg="${5:-}"

  if [ -z "$latch" ] || [ -z "$interval" ] || [ -z "$msg" ]; then
    alert_latch_log "BUG: notify_and_latch_with_age needs <notify-bin> <latch-file> <latch-value> <realert-interval-secs> <message>"
    return 2
  fi

  local last="${latch}.last" existing
  existing="$(cat "$latch" 2>/dev/null || true)"

  if [ -n "$existing" ] && [ "$existing" = "$value" ]; then
    # Same condition as last time — decide whether it is time to speak up
    # again. first_s comes from the latch file's OWN mtime, never rewritten by
    # a re-alert (only _alert_latch_write, called below on a NEW value, touches
    # it), which is what keeps "first seen" anchored through any number of
    # re-alerts.
    local now_s first_s last_s
    now_s="$(date +%s)"
    first_s="$(stat -c %Y "$latch" 2>/dev/null || echo "$now_s")"
    last_s="$(cat "$last" 2>/dev/null || echo "$first_s")"
    if [ "$(( now_s - last_s ))" -lt "$interval" ]; then
      alert_latch_log "SUPPRESSED: same condition, alerted $(( now_s - last_s ))s ago (re-alert after ${interval}s)"
      return 3
    fi
    if _notify_now_impl "$notify" "$msg — STILL UNRESOLVED after $(( (now_s - first_s) / 3600 ))h"; then
      printf '%s' "$now_s" >"$last" 2>/dev/null || true
      alert_latch_log "RE-NOTIFIED (standing $(( now_s - first_s ))s after the first alert)"
      return 0
    fi
    return 1
  fi

  # New or changed condition: go through the ordinary deliver-then-latch path,
  # and only on a delivery that actually happened, drop any stale .last from a
  # PRIOR value — leaving it absent makes the same-value branch above fall back
  # to the fresh latch's own mtime as "last spoken", which IS this delivery,
  # without a second write. .last exists only once an actual re-alert has
  # happened. A failed delivery touches neither file, same as notify_and_latch.
  if _notify_and_latch_impl "$notify" "$latch" "$value" "$msg"; then
    rm -f "$last" 2>/dev/null || true
    return 0
  fi
  return 1
}

# notify_now <notify-bin> <message>
#
# The latch-less half of the same rule, for the guards' fail-fast alerts — the
# "the audit output was unparseable" / "the scanner could not run" messages that
# exit immediately and keep no latch. There is nothing to withhold on failure
# there, so these were never the permanent-silence bug; they had the OTHER half
# of it, which is that `[ -x "$NOTIFY" ] && ... >/dev/null 2>&1` and
# `"$NOTIFY" ... 2>/dev/null || true` both report a lost alert as a success. A
# guard whose one job is to tell you it could not run should not be able to
# fail at telling you, quietly.
#
#   returns 0 — delivered.
#   returns 1 — not delivered; the reason is on stderr.
notify_now() {
  local _al_errexit=0
  case $- in *e*) _al_errexit=1 ;; esac
  set +e
  _notify_now_impl "$@"
  local _al_rc=$?
  [ "$_al_errexit" -eq 1 ] && set -e
  return "$_al_rc"
}

_notify_now_impl() {
  local notify="${1:-}" msg="${2:-}"
  if [ -z "$msg" ]; then
    alert_latch_log "BUG: notify_now needs <notify-bin> <message>"
    return 2
  fi
  _alert_latch_refuse_if_live_in_test "$notify" || return 1
  if [ -z "$notify" ] || [ ! -x "$notify" ]; then
    alert_latch_log "NOT DELIVERED: notifier missing or not executable: ${notify:-<unset>}." \
      "Message was: $msg"
    return 1
  fi
  local out rc
  out="$("$notify" "$msg" 2>&1)"
  rc=$?
  [ "$rc" -eq 0 ] && return 0
  alert_latch_log "NOT DELIVERED: $notify exited $rc. Notifier said: ${out:-<no output>}." \
    "Message was: $msg"
  return 1
}
