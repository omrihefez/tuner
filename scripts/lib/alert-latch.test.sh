#!/usr/bin/env bash
# alert-latch.test.sh — thin shim running the shared test suite in donefile's
# scripts/lib/alert-latch.test.sh (bt-ea85). Kept as a real file here (not
# deleted) so this repo's own test tooling that globs scripts/lib/*.test.sh
# still picks it up unchanged.
#
# bt-7727: on a hosted CI runner /home/omri/projects/donefile does not
# exist, so the old `exec bash "$ALERT_LATCH_TEST"` with no existence check
# exited 127 the moment this file ran. There is no vendored copy of the
# TEST suite itself (only the library gets a pinned fallback, same as every
# sibling repo) — so when the canonical suite is unreachable, skip cleanly
# with a printed reason and exit 0 instead of claiming a crash is a test
# failure. The library's own CI-fallback behaviour is covered instead by
# alert-latch-ci-fallback.test.sh, which does not depend on this file.
set -uo pipefail
ALERT_LATCH_TEST="${ALERT_LATCH_TEST:-/home/omri/projects/donefile/scripts/lib/alert-latch.test.sh}"
if [ -f "$ALERT_LATCH_TEST" ]; then
  exec bash "$ALERT_LATCH_TEST"
fi
echo "alert-latch.test.sh: shared suite not found at $ALERT_LATCH_TEST -- skipping (expected off Omri's box, e.g. in CI; see bt-7727)" >&2
exit 0
