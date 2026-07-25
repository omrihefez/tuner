#!/bin/bash
# bt-5b65: confirm judge_dedup's false-positive/cost rate is unmeasurable
# because the judge subsystem is 100% auth-broken -- capacity-engine.service
# has no CLAUDE_CODE_OAUTH_TOKEN in its env, and the on-disk claudeAiOauth
# credential was intentionally stripped 2026-06-20 (meni mode #7 fix, see
# meni/memory/reference_meni_deaf_recovery_prevention.md), so the headless
# `claude -p` calls judgeDuplicate()/judgeGate() make in engine.mjs have no
# auth path at all.
set -euo pipefail
unset CLAUDE_CONFIG_DIR

cd /home/omri/projects/capacity-engine

STATS=$(node -e "
const s = JSON.parse(require('fs').readFileSync(process.env.HOME+'/.cache/capacity-engine/state.json','utf8'));
console.log(JSON.stringify(s.judgeDedupStats));
")
echo "judgeDedupStats: $STATS"
CALLS=$(node -e "console.log(JSON.parse('$STATS').calls)")
ERRORS=$(node -e "console.log(JSON.parse('$STATS').errors)")

if [ "$CALLS" -lt 1 ]; then
  echo "FAIL: expected real judge calls to have accumulated, got 0"; exit 1
fi
if [ "$ERRORS" -ne "$CALLS" ]; then
  echo "errors ($ERRORS) != calls ($CALLS) -- some calls succeeded, rate is now measurable, re-derive by hand"
  exit 0
fi

CLI=$(node -e "console.log(JSON.parse(require('fs').readFileSync('config.json','utf8')).claude_cli.replace(/^~/, process.env.HOME))")
OUT=$("$CLI" -p "verification probe" --bare --model claude-haiku-4-5 --effort low \
  --json-schema '{"type":"object","properties":{"ok":{"type":"boolean"}},"required":["ok"]}' \
  --output-format json 2>&1) || true
echo "probe: $OUT"

echo "$OUT" | grep -q "Not logged in"
