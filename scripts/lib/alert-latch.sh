#!/usr/bin/env bash
# alert-latch.sh — ma-c1b2. The one place a guard is allowed to write its
# "already alerted" latch, and the rule that it may only do so after the alert
# actually landed somewhere Omri can read it.
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
# ERREXIT. Two callers (check-crontab-drift.sh, check-vercel-git-disconnected.sh)
# run under `set -euo pipefail`. Without the save/disable/restore below, the very
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
