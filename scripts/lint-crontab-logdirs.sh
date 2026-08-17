#!/usr/bin/env bash
# lint-crontab-logdirs.sh — refuses a crontab line whose log redirect can
# abort before the command runs (ma-5896).
#
# Vendored verbatim from meniapp/scripts/lint-crontab-logdirs.sh (ma-0540) —
# it is a static, dependency-free check (reads a crontab file or `-` for
# stdin), so each repo that installs its own cron entries carries its own
# copy rather than shelling out across repos. Re-sync by copying meniapp's
# version if it changes.
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
# Usage:
#   scripts/lint-crontab-logdirs.sh                 # lint deploy/crontab.meniapp
#   scripts/lint-crontab-logdirs.sh <file>          # lint another crontab file
#   crontab -l | scripts/lint-crontab-logdirs.sh -  # lint the live crontab
#
# Exit 0 = every redirect is guarded. Exit 1 = at least one is not (the fix is
# printed per offending line). Exit 2 = usage/read error.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CRON_BLOCK="${1:-${CRON_BLOCK:-$REPO_ROOT/deploy/crontab.meniapp}}"

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

  if [[ "$trimmed" == @* ]]; then
    cmd="${trimmed#* }"                           # @reboot / @daily / ...
    [ "$cmd" = "$trimmed" ] && continue           # a bare @keyword with no command
  else
    read -r _m _h _dom _mon _dow cmd <<<"$trimmed"
    [ -n "${cmd:-}" ] || continue
  fi

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
