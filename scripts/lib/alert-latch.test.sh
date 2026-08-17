#!/usr/bin/env bash
# alert-latch.test.sh — ma-c1b2. Unit coverage for the delivery/latch contract
# in alert-latch.sh, at the edges a real guard cannot easily be driven to: the
# individual meni-notify exit codes, an unwritable state directory, a
# pre-existing latch that must survive a failed delivery untouched, and the
# errexit save/restore that two callers depend on.
#
# The end-to-end half of the proof lives in scripts/guard-alert-latch.test.sh,
# which drives seven real guards through the same cycle.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="$HERE/alert-latch.sh"

pass=0
fail() { echo "FAIL: $*" >&2; exit 1; }
ok() { echo "  ok — $*"; pass=$((pass + 1)); }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

# shellcheck source=alert-latch.sh
. "$LIB"

# stub_notify <exit-code> — a notifier that records its call and exits as told.
CALLS="$TMP/calls"
stub_notify() {
  # Deliberately two statements: in a single `local rc=.. path=..$rc..`, bash
  # expands every word before the builtin runs, so $rc is still unset there.
  local rc="$1"
  local path="$TMP/notify-$rc"
  cat >"$path" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >>"$CALLS"
echo "stub notifier speaking (exit $rc)" >&2
exit $rc
EOF
  chmod +x "$path"
  echo "$path"
}

echo "1. delivered (exit 0) -> latch written with exactly the given value"
LATCH="$TMP/case1/latch"; : >"$CALLS"
notify_and_latch "$(stub_notify 0)" "$LATCH" "fingerprint-aaa" "hello" 2>/dev/null
rc=$?
[ "$rc" -eq 0 ] || fail "expected 0 on a delivered alert, got $rc"
[ "$(cat "$LATCH")" = "fingerprint-aaa" ] || fail "latch holds '$(cat "$LATCH")', expected 'fingerprint-aaa'"
[ ! -e "$LATCH.undelivered" ] || fail "a delivered alert must leave no undelivered breadcrumb"
[ "$(wc -l <"$CALLS")" -eq 1 ] || fail "expected exactly one notifier call"
ok "latched on success, value intact, no breadcrumb"

echo "2. notifier exits non-zero -> no latch, non-zero return, failure LOGGED"
LATCH="$TMP/case2/latch"; : >"$CALLS"
err="$(notify_and_latch "$(stub_notify 1)" "$LATCH" "fingerprint-bbb" "hello" 2>&1)"
rc=$?
[ "$rc" -eq 1 ] || fail "expected 1 on a failed delivery, got $rc"
[ ! -e "$LATCH" ] || fail "latch was written despite a failed delivery — the ma-c1b2 bug"
grep -q "NOT DELIVERED" <<<"$err" || fail "failure was swallowed, not logged: $err"
grep -q "exited 1" <<<"$err" || fail "log does not name the exit code: $err"
grep -q "stub notifier speaking" <<<"$err" || fail "log does not carry the notifier's own diagnosis: $err"
ok "no latch, and the notifier's own explanation is surfaced"

echo "3. each meni-notify failure code is a delivery failure (2 partial, 3 4xx-refused, 4 refused)"
for code in 2 3 4 127; do
  LATCH="$TMP/case3-$code/latch"
  err="$(notify_and_latch "$(stub_notify "$code")" "$LATCH" "sig" "hello" 2>&1)"
  [ $? -eq 1 ] || fail "exit $code should be a delivery failure"
  [ ! -e "$LATCH" ] || fail "exit $code latched anyway"
  grep -q "notifier-exit-$code" "$LATCH.undelivered" || fail "breadcrumb for exit $code missing/wrong: $(cat "$LATCH.undelivered" 2>/dev/null)"
done
ok "2/3/4/127 all withhold the latch and are recorded by code"

echo "4. missing or non-executable notifier is a FAILURE, not a no-op"
LATCH="$TMP/case4/latch"
err="$(notify_and_latch "$TMP/no-such-notifier" "$LATCH" "sig" "hello" 2>&1)"
[ $? -eq 1 ] || fail "a missing notifier must return 1"
[ ! -e "$LATCH" ] || fail "a missing notifier latched anyway — this was hole #1"
grep -q "not executable" <<<"$err" || fail "missing notifier not explained: $err"
grep -q "notifier-not-executable" "$LATCH.undelivered" || fail "breadcrumb missing for a missing notifier"

NONEXEC="$TMP/notify-nonexec"; echo '#!/bin/sh' >"$NONEXEC"; chmod -x "$NONEXEC"
LATCH="$TMP/case4b/latch"
notify_and_latch "$NONEXEC" "$LATCH" "sig" "hello" 2>/dev/null
[ $? -eq 1 ] || fail "a non-executable notifier must return 1"
[ ! -e "$LATCH" ] || fail "a non-executable notifier latched anyway"

LATCH="$TMP/case4c/latch"
notify_and_latch "" "$LATCH" "sig" "hello" 2>/dev/null
[ $? -eq 1 ] || fail "an unset notifier must return 1"
[ ! -e "$LATCH" ] || fail "an unset notifier latched anyway"
ok "missing / non-executable / unset all withhold the latch"

echo "5. a PRE-EXISTING latch survives a failed delivery byte-for-byte"
# The wording in the task is 'left untouched', and it matters: clobbering an
# older fingerprint would make an unrelated, already-announced condition
# re-announce, which is the opposite failure and just as wrong.
LATCH="$TMP/case5/latch"; mkdir -p "$TMP/case5"
printf 'older-fingerprint\n' >"$LATCH"
before="$(sha256sum "$LATCH" | cut -d' ' -f1)"
notify_and_latch "$(stub_notify 1)" "$LATCH" "newer-fingerprint" "hello" 2>/dev/null
[ "$(sha256sum "$LATCH" | cut -d' ' -f1)" = "$before" ] || fail "an existing latch was modified by a FAILED delivery: $(cat "$LATCH")"
ok "existing latch untouched"

echo "6. breadcrumb is cleared once delivery succeeds"
LATCH="$TMP/case6/latch"
notify_and_latch "$(stub_notify 1)" "$LATCH" "sig" "hello" 2>/dev/null
[ -s "$LATCH.undelivered" ] || fail "expected a breadcrumb after the failed run"
notify_and_latch "$(stub_notify 0)" "$LATCH" "sig" "hello" 2>/dev/null
[ ! -e "$LATCH.undelivered" ] || fail "breadcrumb survived a successful delivery"
[ "$(cat "$LATCH")" = "sig" ] || fail "latch not written on the recovery run"
ok "retry after a failure latches and clears the breadcrumb"

echo "7. delivered but the latch cannot be written -> says so, returns non-zero"
RO="$TMP/readonly"; mkdir -p "$RO"; chmod 500 "$RO"
err="$(notify_and_latch "$(stub_notify 0)" "$RO/latch" "sig" "hello" 2>&1)"
rc=$?
if [ "$(id -u)" -eq 0 ]; then
  echo "  (skipped the unwritable-dir assertion: running as root, which ignores mode 500)"
else
  [ "$rc" -eq 1 ] || fail "an unwritable latch path must not report success, got $rc"
  grep -q "DELIVERED, but could NOT write the latch" <<<"$err" || fail "unwritable latch not explained: $err"
fi
chmod 700 "$RO"
ok "an unwritable latch path is reported, never silently succeeded"

echo "8. missing arguments are a caller bug (2), and still write no latch"
LATCH="$TMP/case8/latch"
notify_and_latch "$(stub_notify 0)" "$LATCH" "sig" "" 2>/dev/null
[ $? -eq 2 ] || fail "expected 2 for a missing message"
[ ! -e "$LATCH" ] || fail "a caller bug latched anyway"
ok "argument bugs return 2 and latch nothing"

echo "9. a caller under 'set -e' reaches the log line, and keeps its errexit"
# Without the save/disable/restore in notify_and_latch, capturing the output of
# a notifier that exited non-zero aborts the caller on the spot — the delivery
# failure would be invisible all over again.
PROBE="$TMP/errexit-probe.sh"
cat >"$PROBE" <<EOF
#!/usr/bin/env bash
set -euo pipefail
. "$LIB"
notify_and_latch "$(stub_notify 1)" "$TMP/case9/latch" "sig" "hello" || true
echo "REACHED-AFTER-FAILED-DELIVERY"
case \$- in *e*) echo "ERREXIT-STILL-ON" ;; *) echo "ERREXIT-LOST" ;; esac
EOF
chmod +x "$PROBE"
out="$(bash "$PROBE" 2>&1)"
grep -q "NOT DELIVERED" <<<"$out" || fail "set -e caller never logged the failure: $out"
grep -q "REACHED-AFTER-FAILED-DELIVERY" <<<"$out" || fail "set -e caller aborted inside notify_and_latch: $out"
grep -q "ERREXIT-STILL-ON" <<<"$out" || fail "notify_and_latch left errexit off in a set -e caller: $out"
[ ! -e "$TMP/case9/latch" ] || fail "set -e path latched on a failed delivery"
ok "errexit is neither tripped early nor lost"

echo "10. notify_now (the latch-less alerts) reports its delivery result"
: >"$CALLS"
notify_now "$(stub_notify 0)" "hello" 2>/dev/null
[ $? -eq 0 ] || fail "notify_now must return 0 on a delivered alert"
err="$(notify_now "$(stub_notify 1)" "hello" 2>&1)"
[ $? -eq 1 ] || fail "notify_now must return 1 on a failed alert"
grep -q "NOT DELIVERED" <<<"$err" || fail "notify_now swallowed the failure: $err"
err="$(notify_now "$TMP/no-such-notifier" "hello" 2>&1)"
[ $? -eq 1 ] || fail "notify_now must return 1 when the notifier is missing"
grep -q "not executable" <<<"$err" || fail "notify_now did not explain a missing notifier: $err"
ok "delivered / failed / missing are all distinguishable"

echo
echo "PASS — $pass/10 checks"
