#!/usr/bin/env bash
# ma-04c1: runs the shared ambient-GIT_DIR *.test.sh scrub lint (meniapp's
# lint-testsh-gitdir-scrub.sh, th-cf17/th-682e) against this repo's scripts/
# before the scripts/*.test.sh loop in package.json's "test"/"test:unit" runs
# those fixtures for real. Git exports GIT_DIR/GIT_WORK_TREE into every hook,
# and this loop runs from the donefile-installed pre-push hook (`npm run
# build && npm test`) -- an unscrubbed fixture that drives git at a path of
# its own choosing would mutate THIS repo instead of its own scratch repo.
#
# Skips gracefully off the meni VPS: the shared implementation lives in
# meniapp (ma-ea76, consolidated out of trips-hub) on the SAME box as this
# repo's pre-push hook runs, by absolute path -- same no-per-repo-vendored-
# copy convention as every other repo on this box (ma-b531). CI
# (.github/workflows/ci.yml's "Unit tests" step, `npm test` on ubuntu-latest)
# has no meniapp checkout to point at, so it has nothing to check this
# against; the pre-push hook on the VPS is the real gate here, same division
# as every other repo wiring this in (none of them call it from CI either).
set -uo pipefail

GITDIR_SCRUB_LINT="${GITDIR_SCRUB_LINT:-/home/omri/projects/meniapp/scripts/lint-testsh-gitdir-scrub.sh}"

if [ ! -f "$GITDIR_SCRUB_LINT" ]; then
  echo "gitdir-scrub lint: meniapp not checked out at $GITDIR_SCRUB_LINT -- skipping (expected off the meni VPS, e.g. in CI)" >&2
  exit 0
fi

bash "$GITDIR_SCRUB_LINT" "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/scripts"
