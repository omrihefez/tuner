#!/usr/bin/env bash
# Regression test for scripts/lib/domain-registry.sh (bt-a7a3). Asserts the
# meniapp copy of derive_registry_hosts() hasn't silently drifted from this
# repo's copy -- the two files live in separate git repos with no shared
# package, and until now the only thing asserting they match was a comment
# in their own headers. Neither repo's own suite ever opened the other's
# copy: meniapp's domain-registry.test.sh sources only its own file, and
# this repo's consumers (audit-domains.sh, check-tunnel-liveness.sh) source
# only this repo's copy.
#
# Compares only the FUNCTION BODY, not the whole file: the header prose
# deliberately differs between the two copies -- each is written
# repo-relative ("this repo's audit-domains.sh" here vs
# "bass-tuner/scripts/audit-domains.sh" in meniapp's), and both files
# happen to be 47 lines -- so a whole-file diff/sha256 goes red on
# unmodified HEAD in both repos, which is the shape of check that gets
# disabled rather than fixed.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OURS="$HERE/domain-registry.sh"
THEIRS="${DOMAIN_REGISTRY_MENIAPP_COPY:-/home/omri/projects/meniapp/scripts/lib/domain-registry.sh}"

extract_body() {
  # From the derive_registry_hosts() signature to the function's own
  # closing brace. The awk block inside it is indented, so no line of it
  # starts with a bare "}" -- only the function's real closer does, which
  # is what keeps this a single, un-nested sed range.
  sed -n '/^derive_registry_hosts()/,/^}/p' "$1"
}

[ -r "$OURS" ] || { echo "FAIL: can't read $OURS"; exit 1; }

if [ ! -r "$THEIRS" ]; then
  echo "SKIP: meniapp copy unreadable at $THEIRS -- cannot compare, not asserting agreement"
  exit 0
fi

ours_body="$(extract_body "$OURS")"
theirs_body="$(extract_body "$THEIRS")"

[ -n "$ours_body" ] || { echo "FAIL: derive_registry_hosts() body not found in $OURS -- extraction broke"; exit 1; }
[ -n "$theirs_body" ] || { echo "FAIL: derive_registry_hosts() body not found in $THEIRS -- extraction broke"; exit 1; }

if [ "$ours_body" != "$theirs_body" ]; then
  echo "FAIL: derive_registry_hosts() body differs between $OURS and $THEIRS"
  diff <(echo "$ours_body") <(echo "$theirs_body")
  exit 1
fi

echo "OK: derive_registry_hosts() body is identical in bass-tuner and meniapp"
exit 0
