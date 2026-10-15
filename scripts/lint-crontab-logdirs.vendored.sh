#!/usr/bin/env bash
# lint-crontab-logdirs.vendored.sh (bt-a5ff) -- PINNED CI FALLBACK, NOT THE
# CANONICAL SOURCE. install-monitoring-crons.sh and install-cert-renewal-
# cron.sh both call meniapp's canonical scripts/lint-crontab-logdirs.sh by
# absolute path, /home/omri/projects/meniapp/scripts/lint-crontab-logdirs.sh
# -- a path that exists on Omri's own box but never on a hosted GitHub
# Actions runner (.github/workflows/ci.yml: runs-on: ubuntu-latest, which
# checks out this repo alone). Every CI "Unit tests" run has been failing on
# this since 2026-10-15: `bash: .../lint-crontab-logdirs.sh: No such file or
# directory`, which install-monitoring-crons.sh's own guard correctly turns
# into "refusing to install" / exit 1, and
# scripts/crontab-empty-read-guard.test.sh's control case ("a real crontab
# present ... the guard must not block a normal install") fails on that exit.
#
# Same shim/vendored-pin convention iac-fc0d completed fleet-wide
# (iac/docs/iac-fc0d-canonical-scripts-on-ci.md) and this repo already uses
# for crontab-install-lock.sh, stale-checkout-guard.sh and alert-latch.sh:
# each consumer prefers the live canonical path so a local run on Omri's box
# always picks up meniapp's fixes immediately, and falls back to this pinned
# snapshot only where the canonical is structurally unreachable (CI).
#
# This file is a manually-synced snapshot (copied verbatim below) and WILL
# drift if meniapp's copy changes and nobody re-copies it here -- that is the
# tradeoff for CI being able to run this suite at all.
# check-vendored-pin-drift.sh (meniapp, ma-2aba/ma-42bf) watches this file
# against meniapp's canonical by function name and alerts on drift; keep this
# pin current rather than relying on that guard to catch staleness late.
# Re-sync by hand: splice meniapp's scripts/lint-crontab-logdirs.sh body in
# below this header -- a bare `cp` overwrites this header along with the body.
#
# --- verbatim copy of meniapp's scripts/lint-crontab-logdirs.sh starts here ---
# lint-crontab-logdirs.sh — refuses a crontab line whose log redirect can
# abort before the command runs (ma-5896).
#
# cron sets up `>>` BEFORE exec'ing the command, so a redirect into a directory
# that does not exist kills the line in /bin/sh with "Directory nonexistent" —
# the command never runs, including its own `mkdir -p`. The line looks perfect
# in `crontab -l` and has never emitted a byte. scripts/repro-cron-logdir-abort.sh
# proves the mechanism; three monitors and the ma-635d delivery probe were found
# dead this way on 2026-07-31.
#
# The rule enforced here: every redirect target's parent directory must be
# created BY THE SAME LINE, as a separate command ahead of the redirect:
#
#     */10 * * * * mkdir -p /path/to/state && /path/to/script.sh >> /path/to/state/cron.log 2>&1
#
# This is a STATIC check on purpose — it asserts the shape of the line, not
# whether the directory happens to exist on the box running the lint. That way
# it holds in CI, in a fresh worktree, and on a rebuilt VPS where none of the
# state directories exist yet, which is precisely the case that breaks. The
# runtime half — a line that IS installed but is producing no output — is
# scripts/check-cron-log-staleness.sh.
#
# Vendored by hand into tik-api, trips-hub, second-brain, iac and bass-tuner
# until ma-b531 collapsed those five copies into this one implementation —
# same pattern as check-crontab-drift.sh's own ma-c616 consolidation. Each of
# those repos' installers now calls this file by absolute path
# (/home/omri/projects/meniapp/scripts/lint-crontab-logdirs.sh); all these
# cron entries run on the meni VPS, the same box meniapp lives on, so the
# absolute path always resolves. check-vendored-guard-drift.sh alerts if a
# private copy ever reappears in one of those repos.
#
# Usage:
#   scripts/lint-crontab-logdirs.sh                 # lint deploy/crontab.meniapp
#   scripts/lint-crontab-logdirs.sh <file>          # lint another crontab file
#   crontab -l | scripts/lint-crontab-logdirs.sh -  # lint the live crontab
#
# IGNORE_LIST (ma-822f): a file of plain substrings, one per line (blank lines
# and `#`-comments skipped), each matched against the FULL trimmed cron line
# via a literal (non-regex) substring test. A line matched by any entry is
# skipped entirely — not counted, not flagged — same treatment as a comment.
# For genuinely third-party/system lines that will never carry the mkdir-p
# guard and are not this fleet's to fix. Defaults to
# deploy/crontab-fleet-ignore.txt; unset/missing means nothing is ignored.
#
# Exit 0 = every redirect is guarded. Exit 1 = at least one is not (the fix is
# printed per offending line). Exit 2 = usage/read error.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CRON_BLOCK="${1:-${CRON_BLOCK:-$REPO_ROOT/deploy/crontab.meniapp}}"
IGNORE_LIST="${IGNORE_LIST:-$REPO_ROOT/deploy/crontab-fleet-ignore.txt}"

# Loads IGNORE_LIST into the IGNORE_PATTERNS array, once. Missing/absent file
# means an empty list — nothing is exempt by default.
IGNORE_PATTERNS=()
if [ -n "$IGNORE_LIST" ] && [ -r "$IGNORE_LIST" ]; then
  while IFS= read -r pat; do
    pat="${pat#"${pat%%[![:space:]]*}"}"
    [ -n "$pat" ] || continue
    case "$pat" in \#*) continue ;; esac
    IGNORE_PATTERNS+=("$pat")
  done <"$IGNORE_LIST"
fi

is_ignored() {
  local line="$1" pat
  for pat in "${IGNORE_PATTERNS[@]+"${IGNORE_PATTERNS[@]}"}"; do
    case "$line" in *"$pat"*) return 0 ;; esac
  done
  return 1
}

# Redirect targets that never need a parent directory created.
is_exempt_target() {
  case "$1" in
    /dev/null|/dev/stdout|/dev/stderr|/dev/fd/*) return 0 ;;
    *) return 1 ;;
  esac
}

# Splits "<args> && <rest>" (or "; ") at the FIRST separator.
# Sets SPLIT_HEAD / SPLIT_TAIL.
split_at_separator() {
  local s="$1" head_amp head_semi
  head_amp="${s%%&&*}"
  head_semi="${s%%;*}"
  if [ "$head_amp" = "$s" ] && [ "$head_semi" = "$s" ]; then
    SPLIT_HEAD="$s"; SPLIT_TAIL=""
    return 1                      # no separator at all
  fi
  if [ "${#head_amp}" -le "${#head_semi}" ]; then
    SPLIT_HEAD="$head_amp"; SPLIT_TAIL="${s#*&&}"
  else
    SPLIT_HEAD="$head_semi"; SPLIT_TAIL="${s#*;}"
  fi
  return 0
}

# Every directory the command creates in its leading `mkdir -p ... &&` prefix,
# one per line. Only the LEADING run counts: an mkdir after the redirect has
# already been set up is too late to help, which is the whole bug.
guarded_dirs() {
  local cmd="$1"
  while :; do
    cmd="${cmd#"${cmd%%[![:space:]]*}"}"          # ltrim
    [[ "$cmd" == mkdir\ * ]] || break
    local rest="${cmd#mkdir }"
    rest="${rest#"${rest%%[![:space:]]*}"}"
    [[ "$rest" == -p\ * ]] || break               # bare `mkdir` is not idempotent; don't credit it
    rest="${rest#-p }"
    if split_at_separator "$rest"; then
      printf '%s\n' $SPLIT_HEAD                   # deliberately unquoted: split on whitespace
      cmd="$SPLIT_TAIL"
    else
      printf '%s\n' $rest
      break
    fi
  done
}

# Every path a redirect writes to, one per line. `2>&1`-style fd dups produce a
# target starting with "&" and are dropped.
redirect_targets() {
  local cmd="$1" tok
  # Normalises "N>> path" / ">>path" alike; the trailing token is the target.
  while read -r tok; do
    tok="${tok##*>}"                              # strip the operator
    tok="${tok#"${tok%%[![:space:]]*}"}"          # ltrim
    [ -n "$tok" ] || continue
    case "$tok" in \&*) continue ;; esac
    printf '%s\n' "$tok"
  done < <(grep -oE '[0-9&]*>>?[[:space:]]*[^[:space:]]*' <<<"$cmd" || true)
}

# Strips a trailing, UNQUOTED `# ...` comment off a cron command (ce-bb28).
# This fleet's convention is to end every installed cron line with
# `# <task-id> — <description>` after the real command, and that prose
# routinely contains a literal '>' (an arrow like "->", or just text) that
# redirect_targets' regex cannot tell apart from a real shell redirect
# operator -- house-control's `mkdir -p /home/omri/.meni && ... >>
# .../health.log 2>&1   # hc-024b — Sonos->Spotify Connect link` was flagged
# as an unguarded redirect to a bogus target "Spotify" (parent ".") for
# exactly this reason, even though the real redirect IS guarded.
# Quote-aware on purpose: several installers' drift-check lines embed a
# literal '#' INSIDE a quoted value on the command itself (`BEGIN_MARK="#
# BEGIN foo (...)"`), which is not a comment start and must survive intact --
# a naive `${cmd%%#*}` truncates those lines at that quoted '#' and throws
# away the real redirect the rest of the line contains.
strip_trailing_comment() {
  local s="$1" i c in_dq=0 in_sq=0
  for (( i = 0; i < ${#s}; i++ )); do
    c="${s:$i:1}"
    if [ "$in_sq" -eq 1 ]; then
      [ "$c" = "'" ] && in_sq=0
      continue
    fi
    if [ "$in_dq" -eq 1 ]; then
      [ "$c" = '"' ] && in_dq=0
      continue
    fi
    case "$c" in
      "'") in_sq=1 ;;
      '"') in_dq=1 ;;
      '#') printf '%s\n' "${s:0:i}"; return ;;
    esac
  done
  printf '%s\n' "$s"
}

# A dir is covered if the line mkdir -p'd it, or mkdir -p'd something BELOW it
# (mkdir -p a/b/c necessarily creates a/b).
is_covered() {
  local need="$1" d
  shift
  for d in "$@"; do
    [ "$d" = "$need" ] && return 0
    case "$d" in "$need"/*) return 0 ;; esac
  done
  return 1
}

if [ "$CRON_BLOCK" = "-" ]; then
  INPUT="$(cat)"
elif [ -r "$CRON_BLOCK" ]; then
  INPUT="$(cat "$CRON_BLOCK")"
else
  echo "lint-crontab-logdirs: cannot read crontab file: $CRON_BLOCK" >&2
  exit 2
fi

checked=0
bad=0
lineno=0

while IFS= read -r line; do
  lineno=$((lineno + 1))
  trimmed="${line#"${line%%[![:space:]]*}"}"
  [ -n "$trimmed" ] || continue
  case "$trimmed" in \#*) continue ;; esac
  # crontab environment assignments (FOO=bar) are not entries
  [[ "$trimmed" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]] && continue
  is_ignored "$trimmed" && continue

  if [[ "$trimmed" == @* ]]; then
    cmd="${trimmed#* }"                           # @reboot / @daily / ...
    [ "$cmd" = "$trimmed" ] && continue           # a bare @keyword with no command
  else
    read -r _m _h _dom _mon _dow cmd <<<"$trimmed"
    [ -n "${cmd:-}" ] || continue
  fi
  cmd="$(strip_trailing_comment "$cmd")"

  mapfile -t targets < <(redirect_targets "$cmd")
  [ "${#targets[@]}" -gt 0 ] || continue          # no redirect, nothing to abort on
  mapfile -t dirs < <(guarded_dirs "$cmd")

  for target in "${targets[@]}"; do
    is_exempt_target "$target" && continue
    checked=$((checked + 1))
    parent="$(dirname -- "$target")"
    if ! is_covered "$parent" "${dirs[@]+"${dirs[@]}"}"; then
      bad=$((bad + 1))
      echo "✗ $CRON_BLOCK:$lineno — redirect to $target with nothing creating $parent" >&2
      echo "    $trimmed" >&2
      echo "    fix: prefix the command with 'mkdir -p $parent && '" >&2
      echo "    why: cron opens the redirect before running the command; if $parent is" >&2
      echo "         absent /bin/sh aborts and the command NEVER runs (ma-5896)." >&2
      echo >&2
    fi
  done
done <<<"$INPUT"

if [ "$bad" -gt 0 ]; then
  echo "lint-crontab-logdirs: $bad unguarded redirect(s) of $checked in $CRON_BLOCK." >&2
  echo "See scripts/repro-cron-logdir-abort.sh for the mechanism." >&2
  exit 1
fi

echo "lint-crontab-logdirs: OK — all $checked redirect target(s) in $CRON_BLOCK have their parent directory created by the same line."
exit 0
