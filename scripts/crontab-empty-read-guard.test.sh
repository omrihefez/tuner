#!/usr/bin/env bash
# Hermetic regression test for the empty/failed-crontab-read guard (bt-59c4,
# ported from meni-arch's ar-9eb3 / scripts/crontab-empty-read-guard.test.sh —
# porting the installers without porting this test would leave the port
# unverified).
#
# This repo's three scripts/install-*-cron.sh installers each read the live
# crontab, strip their own marker block out, and write the result back with
# `crontab -`. Before this guard, the read was
# `current="$(crontab -l 2>/dev/null || true)"` -- `|| true` swallows a
# failed read's exit status, so a failed `crontab -l` and a genuinely empty
# crontab both collapse to the same empty $current, and the installer then
# writes a crontab containing ONLY its own block, silently dropping every
# unrelated job on the box.
#
# Drives each installer with a stubbed `crontab` binary (never the real
# one -- this must never touch the live crontab) under three scenarios:
# `crontab -l` fails, `crontab -l` succeeds but prints nothing, and
# `crontab -l` succeeds with real content. In the first two, the installer
# must exit non-zero and never invoke `crontab -` (the write). In the third,
# it must proceed normally. A fourth scenario proves the escape hatch: the
# empty case passed --allow-empty-base must proceed.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

INSTALLERS=(
  install-monitoring-crons.sh
  install-cert-renewal-cron.sh
  install-ff-sync-cron.sh
)

pass_count=0
fail() { echo "FAIL: $*" >&2; exit 1; }
ok() { pass_count=$((pass_count + 1)); echo "ok: $*"; }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

STUB_DIR="$TMP/bin"
mkdir -p "$STUB_DIR"
CRONTAB_STUB="$STUB_DIR/crontab"
cat > "$CRONTAB_STUB" <<'EOF'
#!/usr/bin/env bash
# Fake crontab(1) for the guard test. Never the real crontab binary.
# install-ff-sync-cron.sh re-reads with `crontab -l` right after writing to
# echo the result, so a write must be reflected in subsequent reads --
# tracked in $CRONTAB_STUB_STATE, which a write (`-`) populates.
echo "$*" >> "$CRONTAB_STUB_CALLS"
case "$1" in
  -l)
    if [ -f "$CRONTAB_STUB_STATE" ]; then
      cat "$CRONTAB_STUB_STATE"
    else
      case "$CRONTAB_STUB_MODE" in
        fail)  exit 1 ;;
        empty) printf ''; exit 0 ;;
        ok)    cat "$CRONTAB_STUB_DATA" ;;
      esac
    fi
    ;;
  -)
    cat > "$CRONTAB_STUB_WRITE"
    cp "$CRONTAB_STUB_WRITE" "$CRONTAB_STUB_STATE"
    ;;
esac
EOF
chmod +x "$CRONTAB_STUB"

# A real-looking existing crontab, standing in for this box's 222 entries --
# the thing a wipe would silently destroy.
REAL_CRONTAB="$TMP/real-crontab.txt"
cat > "$REAL_CRONTAB" <<'EOF'
*/5 * * * * /home/omri/some/unrelated-job.sh
17 6 * * * /home/omri/another/unrelated-job.sh
EOF

run_installer() {
  local script="$1" mode="$2"; shift 2
  local calls="$TMP/calls.txt" write="$TMP/write.txt" state="$TMP/state.txt"
  : > "$calls"; rm -f "$write" "$state"
  # bt-e986: this test is about the empty-read guard, not staleness. Without
  # this, any commit that changes a rendered block fails here until it is on
  # origin/main (the stale-checkout guard compares against origin's render).
  PATH="$STUB_DIR:$PATH" ALLOW_STALE_CRONTAB_WRITE=1 \
    CRONTAB_STUB_MODE="$mode" CRONTAB_STUB_CALLS="$calls" CRONTAB_STUB_WRITE="$write" \
    CRONTAB_STUB_STATE="$state" CRONTAB_STUB_DATA="$REAL_CRONTAB" \
    CRONTAB_INSTALL_LOCK_FILE="$TMP/lock-$$" \
    "$HERE/$script" "$@" >"$TMP/out.txt" 2>"$TMP/err.txt"
  echo "$?"
}

wrote_crontab() { [ -s "$TMP/write.txt" ]; }

for script in "${INSTALLERS[@]}"; do
  SCRIPT_PATH="$HERE/$script"
  [ -x "$SCRIPT_PATH" ] || fail "$script: not found or not executable at $SCRIPT_PATH"

  # --- RED-shaped case 1: crontab -l fails -------------------------------
  rc="$(run_installer "$script" fail)"
  if [ "$rc" = "0" ] || wrote_crontab; then
    fail "$script: with crontab -l failing, installer exited $rc and wrote_crontab=$(wrote_crontab && echo yes || echo no) -- it must exit non-zero and never call 'crontab -'. stderr: $(cat "$TMP/err.txt")"
  fi
  ok "$script: refuses and never writes when crontab -l fails"

  # --- RED-shaped case 2: crontab -l succeeds but prints nothing ---------
  rc="$(run_installer "$script" empty)"
  if [ "$rc" = "0" ] || wrote_crontab; then
    fail "$script: with crontab -l empty, installer exited $rc and wrote_crontab=$(wrote_crontab && echo yes || echo no) -- it must exit non-zero and never call 'crontab -'. stderr: $(cat "$TMP/err.txt")"
  fi
  ok "$script: refuses and never writes when crontab -l returns nothing"

  # --- control: normal read with real content still installs cleanly ----
  rc="$(run_installer "$script" ok)"
  if [ "$rc" != "0" ] || ! wrote_crontab; then
    fail "$script: with a real crontab present, installer exited $rc and wrote_crontab=$(wrote_crontab && echo yes || echo no) -- the guard must not block a normal install. stderr: $(cat "$TMP/err.txt")"
  fi
  # the unrelated jobs from the stubbed existing crontab must survive the write
  grep -qF "unrelated-job.sh" "$TMP/write.txt" \
    || fail "$script: normal install dropped the pre-existing unrelated crontab entries"
  ok "$script: normal install preserves existing unrelated entries"

  # --- escape hatch: --allow-empty-base proceeds on an empty read --------
  rc="$(run_installer "$script" empty --allow-empty-base)"
  if [ "$rc" != "0" ] || ! wrote_crontab; then
    fail "$script --allow-empty-base: with crontab -l empty, installer exited $rc and wrote_crontab=$(wrote_crontab && echo yes || echo no) -- the explicit opt-in must still allow a genuine first install. stderr: $(cat "$TMP/err.txt")"
  fi
  ok "$script: --allow-empty-base allows a genuine first install over an empty read"
done

echo "passed $pass_count checks across ${#INSTALLERS[@]} installers"
