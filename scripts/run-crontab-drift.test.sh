#!/usr/bin/env bash
# bt-e986: run-crontab-drift.sh hands the shared checker exactly the env each
# installer's old inline DRIFT_LINE did, and every installer's rendered line
# stays short and points at the wrapper.
set -u
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
fail=0
cat > "$tmp/stub.sh" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$BLOCK_LABEL" "$BEGIN_MARK" "$END_MARK" "$EXPECTED_CONTENT_CMD" "$INSTALLER_HINT"
STUB
chmod +x "$tmp/stub.sh"
DRIFT_CHECK="$tmp/stub.sh" "$here/run-crontab-drift.sh" lbl inst.sh "$tmp/state"
want="lbl
# BEGIN lbl (scripts/inst.sh)
# END lbl (scripts/inst.sh)
$here/inst.sh --print-line
scripts/inst.sh"
if [ "$(cat "$tmp/state/cron.log")" = "$want" ]; then echo "OK     wrapper passes label/marks/expected-cmd/hint"; else echo "FAIL   wrapper env:"; cat "$tmp/state/cron.log"; fail=1; fi
for inst in install-cert-renewal-cron.sh install-ff-sync-cron.sh install-monitoring-crons.sh; do
  out="$(bash "$here/$inst" --print-line 2>&1)" || { echo "FAIL   $inst --print-line exited non-zero"; fail=1; continue; }
  line="$(grep run-crontab-drift.sh <<<"$out")"
  max="$(awk '{ if (length>m) m=length } END { print m+0 }' <<<"$line")"
  if [ -z "$line" ]; then echo "FAIL   $inst: no run-crontab-drift.sh line"; fail=1
  elif grep -q 'BEGIN_MARK=' <<<"$line" || [ "$max" -gt 250 ]; then echo "FAIL   $inst: drift line still inlined ($max chars)"; fail=1
  else echo "OK     $inst drift line is $max chars"; fi
done
exit $fail
