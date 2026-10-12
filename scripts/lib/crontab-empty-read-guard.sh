#!/usr/bin/env bash
# crontab-empty-read-guard.sh — bt-59c4 (ported from meni-arch's ar-9eb3,
# meni-arch commit 4d45bf2 — port it, do not invent one).
#
# Every scripts/install-*-cron.sh installer in this repo reads the live
# crontab, strips its own marker block out, and writes the result back with
# `crontab -`. The old idiom, `current="$(crontab -l 2>/dev/null || true)"`,
# swallows a failed read's exit status with `|| true`: a failed `crontab -l`
# and a genuinely empty crontab both collapse to the same empty $current, and
# the installer then writes a crontab containing ONLY its own block --
# silently dropping every unrelated job on the box (this box: 222 active
# entries, measured 2026-10-12).
#
# Deliberately a repo-local lib, same scoping call meni-arch made: this repo
# already sources its OWN scripts/lib/crontab-install-lock.sh for the shared
# lock (not meniapp's canonical lib/crontab-install-lock.sh by absolute
# path), so a second repo-local lib for this guard matches the existing
# convention here rather than introducing a new one.
#
# Still keeps the "capture into a variable, never pipe crontab -l straight
# into a consumer" discipline meniapp's guard prescribes for a real reason
# (ma-518c: the live crontab here is close to the 64KB pipe buffer, so a
# downstream `grep -q` can SIGPIPE the producer and `pipefail` then reports
# that as "not found").
#
# crontab_install_read_or_refuse <allow_empty_base: 0|1>
#   Prints the live crontab on stdout and returns 0.
#   Refuses -- prints nothing on stdout, a FATAL line on stderr, returns 1 --
#   when the read failed OR came back empty, UNLESS allow_empty_base=1. That
#   flag must come from an explicit --allow-empty-base on the installer's own
#   command line (a genuine first install on a box with no crontab yet is
#   real), never inferred from the empty read itself -- inferring it from the
#   read is exactly the bug this guard closes.
crontab_install_read_or_refuse() {
  local allow_empty_base="${1:-0}"
  local out rc=0
  out="$(crontab -l 2>/dev/null)" || rc=$?
  if [ -z "$out" ]; then
    if [ "$allow_empty_base" = "1" ]; then
      printf '%s' ""
      return 0
    fi
    if [ "$rc" -ne 0 ]; then
      echo "FATAL: crontab -l failed (exit $rc). Refusing to write: writing now would replace the live crontab with only this installer's own block, silently dropping every unrelated job on the box. If this box genuinely has no crontab yet, re-run with --allow-empty-base." >&2
    else
      echo "FATAL: crontab -l returned nothing. Refusing to write: installing over an empty table would silently drop every unrelated job on this box. If this box genuinely has no crontab yet, re-run with --allow-empty-base." >&2
    fi
    return 1
  fi
  printf '%s' "$out"
  return 0
}
