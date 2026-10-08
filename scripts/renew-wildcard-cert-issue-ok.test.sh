#!/usr/bin/env bash
# Regression test for scripts/renew-wildcard-cert.sh's issuance_reports_success
# (bt-6791): a plain `grep -qi "success"` on the CLI's free-form output also
# matched "unsuccessful", so a real failure message set issue_ok=1 and the
# script exited 0 -- no alert, and the challenge TXT record got cleaned up as
# if the renewal had worked. Hermetic -- sources the script (which stops
# itself before any network/secrets code runs when sourced, not executed)
# and calls the function directly. No vercel, no Cloudflare, no DNS.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$HERE/renew-wildcard-cert.sh"

pass=0
fail() { echo "FAIL: $*" >&2; exit 1; }
ok() { echo "  ok — $*"; pass=$((pass + 1)); }

# shellcheck disable=SC1090
source "$SCRIPT"

echo "1. the exact false-positive from bt-6791: a failure message containing 'unsuccessful'"
if issuance_reports_success 0 "Certificate issuance was unsuccessful"; then
  fail "'Certificate issuance was unsuccessful' (exit 0) must NOT read as success"
fi
ok "'...unsuccessful' with exit 0 is correctly treated as failure"

echo "2. other unsuccessful-shaped failure text from the task"
for msg in "unsuccessfully issued" "Error: renewal unsuccessful for *.omrihefez.com"; do
  if issuance_reports_success 0 "$msg"; then
    fail "'$msg' (exit 0) must NOT read as success"
  fi
done
ok "all unsuccessful-shaped failure strings correctly treated as failure"

echo "3. a real success message still reads as success"
issuance_reports_success 0 "Success! Certificate for *.omrihefez.com has been issued" \
  || fail "a genuine success message with exit 0 must read as success"
ok "genuine success message (exit 0) reads as success"

echo "4. non-zero exit always fails, even with the word success present"
if issuance_reports_success 1 "Success! Certificate issued"; then
  fail "non-zero exit must never read as success, regardless of output text"
fi
ok "non-zero exit overrides any success-shaped text"

echo "5. a plain failure with no success-shaped words at all"
if issuance_reports_success 1 "Error: something went wrong"; then
  fail "a plain failure must not read as success"
fi
ok "plain failure (non-zero exit, no success text) reads as failure"

echo
echo "PASS ($pass assertions)"
