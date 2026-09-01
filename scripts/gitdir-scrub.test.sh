#!/usr/bin/env bash
# Regression test (sb-f539) for the ambient-GIT_DIR scrub in
# ff-sync-main-checkout.sh.
#
# GIT_DIR/GIT_WORK_TREE OUTRANK a `cd` or `git -C <path>` -- git exports them
# into every hook and every process it spawns, so a caller with either set
# makes every git call in this script silently resolve a DIFFERENT repo than
# the one it was pointed at. Same class and same fix as sb-7d11
# (install-prune-cron.sh, 52897e1), trips-hub's th-cf17, and second-brain's
# sb-be37 (153b522).
#
# Never touches the real fleet: builds two throwaway local repos (no
# network) with DIFFERENT default branches and asserts the script resolves
# the repo it was actually cd'd into, not the ambient one.
set -uo pipefail
# Scrubbed here too, for the same reason the script under test needs it:
# this test itself does git init/-C calls that must target its own scratch
# fixtures, not whatever repo it happens to be invoked from.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY \
  GIT_ALTERNATE_OBJECT_DIRECTORIES

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fail() { echo "FAIL: $*" >&2; exit 1; }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

# --- fixtures: a "real" repo (default branch main) and a "decoy" repo
#     (default branch master, no main branch at all) ---
git init -q -b main "$TMP/real"
git -C "$TMP/real" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init

git init -q -b master "$TMP/decoy"
git -C "$TMP/decoy" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init

# SANITY: fixtures must actually differ, or an ambient-GIT_DIR bug would
# resolve the decoy and still happen to report the right answer.
[ "$(git -C "$TMP/real" branch --show-current)" = "main" ] || \
  fail "test setup: real repo's default branch is not 'main'"
[ "$(git -C "$TMP/decoy" branch --show-current)" = "master" ] || \
  fail "test setup: decoy repo's default branch is not 'master'"

# ff-sync-main-checkout.sh's branch/HEAD resolution must resolve the repo it
# cd'd into, not the ambient GIT_DIR one.
# Extract everything from the scrub through the branch= line (inclusive),
# dropping the REPO_ROOT computation (BASH_SOURCE-based -- irrelevant here,
# we cd straight into the fixture instead) and print the result.
awk '
  /^unset GIT_DIR/ { keep=1 }
  /^REPO_ROOT=/ { next }
  keep { print }
  /^branch="\$\(git rev-parse/ { exit }
' "$HERE/ff-sync-main-checkout.sh" > "$TMP/ffsync-body.sh"
grep -q '^unset GIT_DIR' "$TMP/ffsync-body.sh" || \
  fail "test setup: extracted ff-sync-main-checkout.sh body is missing the scrub -- did the script's structure change?"
grep -q '^branch=' "$TMP/ffsync-body.sh" || \
  fail "test setup: extracted ff-sync-main-checkout.sh body is missing the branch= line -- did the script's structure change?"

cat > "$TMP/ffsync-driver.sh" <<HEADER
cd "$TMP/real" || exit 1
HEADER
cat "$TMP/ffsync-body.sh" >> "$TMP/ffsync-driver.sh"
echo 'echo "$branch"' >> "$TMP/ffsync-driver.sh"

resolved_branch="$(GIT_DIR="$TMP/decoy/.git" GIT_WORK_TREE="$TMP/decoy" bash "$TMP/ffsync-driver.sh")"
[ "$resolved_branch" = "main" ] || \
  fail "ff-sync-main-checkout.sh's HEAD-branch resolution reported '$resolved_branch' while cd'd into \$TMP/real under an ambient GIT_DIR pointing at the decoy (master HEAD) -- expected 'main'."

echo "PASS: ff-sync-main-checkout.sh resolves the repo it cd'd into, not an ambient GIT_DIR (sb-f539)"
