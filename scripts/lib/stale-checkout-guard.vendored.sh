#!/usr/bin/env bash
# stale-checkout-guard.vendored.sh (ma-2f6d) — PINNED CI FALLBACK, NOT THE
# CANONICAL SOURCE. Same defect and same remedy as alert-latch.vendored.sh /
# crontab-install-lock.vendored.sh: scripts/lib/stale-checkout-guard.sh
# sources meniapp's canonical copy by absolute path,
# /home/omri/projects/meniapp/scripts/lib/stale-checkout-guard.sh, which
# exists on Omri's box and never on a hosted CI runner. The source then
# fails and refuse_if_stale_crontab_render is missing entirely.
#
# The consumer falls back to this file only when the canonical path is
# absent, so a local run still sources the live canonical copy and picks up
# fixes immediately; CI degrades to this snapshot.
#
# Manually synced, and WILL drift if meniapp's copy changes and nobody
# re-copies it. Re-sync with:
#   cp /home/omri/projects/meniapp/scripts/lib/stale-checkout-guard.sh \
#      scripts/lib/stale-checkout-guard.vendored.sh
#
# --- verbatim copy of meniapp's scripts/lib/stale-checkout-guard.sh below ---

refuse_if_stale_crontab_render() {
  local script_dir="$1" script_rel_path="$2" print_arg="$3" current_render="$4"
  local origin_branch="${5:-main}"

  [ "${ALLOW_STALE_CRONTAB_WRITE:-0}" = "1" ] && return 0

  # GIT_DIR outranks `git -C` (sb-7d11) — scrub it for this function's own
  # git calls only, scoped to each subshell below. This is dot-sourced into
  # the caller's live shell, so a top-level `unset` would scrub the CALLER's
  # environment for the rest of its run (same caution as
  # dirty-checkout-guard.sh's refuse_if_dirty_checkout).
  local repo_root
  repo_root="$(unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY \
                     GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_PREFIX GIT_COMMON_DIR
               git -C "$script_dir" rev-parse --show-toplevel 2>/dev/null || true)"
  [ -n "$repo_root" ] || return 0

  if ! (unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY \
              GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_PREFIX GIT_COMMON_DIR
        git -C "$repo_root" remote get-url origin) >/dev/null 2>&1; then
    return 0
  fi

  if ! (unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY \
              GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_PREFIX GIT_COMMON_DIR
        timeout 20 git -C "$repo_root" fetch --quiet origin "$origin_branch") 2>/dev/null; then
    echo "[stale-checkout-guard] warning: could not fetch origin/$origin_branch to check this checkout isn't stale (offline?) -- proceeding WITHOUT the stale-checkout guard. Set ALLOW_STALE_CRONTAB_WRITE=1 to silence this warning." >&2
    return 0
  fi

  local origin_tmp origin_render origin_tmp_dir
  # The temp file for origin's copy MUST live in the EXACT SAME directory as
  # <script-rel-path> resolves to inside the repo -- not merely "some
  # directory inside the repo" (a caller-supplied $script_dir one level off,
  # e.g. a repo root instead of the actual scripts/ dir, silently breaks
  # this). Several installers (e.g. tik-api's install-ff-sync-cron.sh, iac's
  # install-cron.sh) derive part of their OWN rendered content from their own
  # location (SCRIPT_DIR/REPO_ROOT via ${BASH_SOURCE[0]}) rather than a
  # hardcoded canonical path -- rendering origin's copy from a different
  # directory then embeds a DIFFERENT path than the real installation and
  # manufactures a mismatch on every single run, a permanent false positive
  # (confirmed 2026-09-14 against install-ff-sync-cron.sh and
  # install-fleet-ci-health-cron.sh: a first fix that placed the temp file in
  # the caller-supplied $script_dir was not enough because those two callers
  # pass their REPO ROOT, one level above scripts/, not the scripts/ dir
  # itself -- deriving the directory from $repo_root + $script_rel_path
  # instead removes the dependency on the caller getting that argument
  # exactly right).
  origin_tmp_dir="$repo_root/$(dirname "$script_rel_path")"
  origin_tmp="$(mktemp "$origin_tmp_dir/.stale-checkout-guard-origin.XXXXXX" 2>/dev/null || mktemp)"
  if ! (unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY \
              GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_PREFIX GIT_COMMON_DIR
        git -C "$repo_root" show "origin/$origin_branch:$script_rel_path") > "$origin_tmp" 2>/dev/null; then
    rm -f "$origin_tmp"
    return 0
  fi

  origin_render="$(bash "$origin_tmp" "$print_arg" 2>/dev/null || true)"
  rm -f "$origin_tmp"

  if [ -n "$origin_render" ] && [ "$origin_render" != "$current_render" ]; then
    echo "[stale-checkout-guard] refusing to install: this checkout of $script_rel_path renders a DIFFERENT crontab block than origin/$origin_branch's copy of the same file -- this checkout is behind. Update it (git pull / fast-forward this repo) and re-run, or set ALLOW_STALE_CRONTAB_WRITE=1 to force installing this exact render anyway." >&2
    return 1
  fi
  return 0
}
