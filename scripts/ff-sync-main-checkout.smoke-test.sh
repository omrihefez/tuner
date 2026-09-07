#!/usr/bin/env bash
# ff-sync-main-checkout.smoke-test.sh — smoke test for this repo's ff-sync wrapper
# (ce-4f1c). Confirms the wrapper's own config (branch/label) is wired
# correctly and that it performs a real fast-forward end to end through the
# shared library. The library's own branching logic (diverged, locking,
# alert-after-N, GIT_DIR scrub, ...) is covered once, centrally, by
# donefile's scripts/lib/ff-sync-checkout-lib.test.sh — this file does not
# re-test that, only that THIS repo's wrapper is wired to the right values.
#
# Run: scripts/ff-sync-main-checkout.smoke-test.sh
set -uo pipefail
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY \
      GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_PREFIX GIT_COMMON_DIR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$SCRIPT_DIR/ff-sync-main-checkout.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

PASS=0; FAIL=0
t_ok()   { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
t_fail() { FAIL=$((FAIL+1)); printf '  FAIL %s\n     %s\n' "$1" "${2:-}"; }
check()  { if [ "$2" = "$3" ]; then t_ok "$1"; else t_fail "$1" "expected '$3', got '$2'"; fi; }

grep -q 'FF_SYNC_BRANCH="main"' "$SCRIPT" && t_ok "wrapper tracks main" || t_fail "wrapper branch" "$(grep FF_SYNC_BRANCH "$SCRIPT")"
grep -q 'FF_SYNC_LABEL="ff-sync-bass-tuner-main-checkout"' "$SCRIPT" && t_ok "wrapper uses expected state-dir label" || t_fail "wrapper label" "$(grep FF_SYNC_LABEL "$SCRIPT")"

git_id() { git -C "$1" config user.email t@example.com && git -C "$1" config user.name test; }

ORIGIN="$TMP/origin.git"
CHECKOUT="$TMP/checkout"
git init -q --bare "$ORIGIN"
git init -q "$TMP/seed"
git_id "$TMP/seed"
echo one > "$TMP/seed/README"
git -C "$TMP/seed" add -A && git -C "$TMP/seed" commit -qm one
git -C "$TMP/seed" branch -M main
git -C "$TMP/seed" remote add origin "$ORIGIN"
git -C "$TMP/seed" push -q origin main
git clone -q "$ORIGIN" "$CHECKOUT"
git -C "$CHECKOUT" checkout -q main
git_id "$CHECKOUT"

mkdir -p "$CHECKOUT/scripts"
cp "$SCRIPT" "$CHECKOUT/scripts/ff-sync-main-checkout.sh"
chmod +x "$CHECKOUT/scripts/ff-sync-main-checkout.sh"
WRAPPER="$CHECKOUT/scripts/ff-sync-main-checkout.sh"

export FF_SYNC_STATE_DIR="$TMP/state"
mkdir -p "$FF_SYNC_STATE_DIR"
export MENI_NOTIFY_BIN=/bin/true

rc=0
"$WRAPPER" >"$TMP/out.log" 2>&1 || rc=$?
check "exit 0 when already in sync" "$rc" "0"

echo two > "$TMP/seed/file2"
git -C "$TMP/seed" add -A && git -C "$TMP/seed" commit -qm two
NEW_SHA="$(git -C "$TMP/seed" rev-parse HEAD)"
git -C "$TMP/seed" push -q origin main
rc=0
"$WRAPPER" >"$TMP/out.log" 2>&1 || rc=$?
check "exit 0 on clean fast-forward" "$rc" "0"
check "checkout advanced to new origin sha" "$(git -C "$CHECKOUT" rev-parse HEAD)" "$NEW_SHA"

echo "passed: $PASS  failed: $FAIL"
[ "$FAIL" -eq 0 ]
