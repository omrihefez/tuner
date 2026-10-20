#!/usr/bin/env bash
# bt-e986: one place for the crontab-drift cron entry's env boilerplate.
# Each installer's DRIFT_LINE used to inline BLOCK_LABEL/BEGIN_MARK/END_MARK/
# EXPECTED_CONTENT_CMD/INSTALLER_HINT/mkdir/log redirect (~330-390 chars, 790
# once the crontab expands it). Now the line is just this script + 3 args.
#
# usage: run-crontab-drift.sh <label> <installer-basename> <state-dir>
#   BEGIN/END marks follow every installer here: "# BEGIN|END <label> (scripts/<installer>)"
#   EXPECTED_CONTENT_CMD is "<this repo>/scripts/<installer> --print-line"
# The shared checker is meniapp's (ma-c616); DRIFT_CHECK overrides it for tests.
set -u
label="${1:?label}"; installer="${2:?installer}"; state_dir="${3:?state-dir}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
check="${DRIFT_CHECK:-/home/omri/projects/meniapp/scripts/check-crontab-drift.sh}"
mkdir -p "$state_dir" || exit 1
BLOCK_LABEL="$label" \
BEGIN_MARK="# BEGIN $label (scripts/$installer)" \
END_MARK="# END $label (scripts/$installer)" \
EXPECTED_CONTENT_CMD="$here/$installer --print-line" \
INSTALLER_HINT="scripts/$installer" \
  "$check" >> "$state_dir/cron.log" 2>&1
