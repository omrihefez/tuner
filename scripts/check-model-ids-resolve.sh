#!/usr/bin/env bash
# bt-5abe: nothing in the fleet asserted that a hardcoded Gemini model ID
# still resolves, so a provider-side retirement ("[Action Required] Migrate
# Gemini 2.5 traffic before Oct 20, 2026") was invisible until a
# user-visible failure. Four repos (kidai, meniapp, meni-music, iac) carried
# live gemini-2.5-* strings past that notice for seven weeks because the
# 2026-08-05 sweep (df-a928) only ever scoped ~/meni/bin/*.
#
# DISCOVERS model IDs by grepping the local repo checkouts for the
# provider's model-ID SHAPE (MODEL_ID_REGEX below), instead of carrying a
# hand-maintained list of model names -- same reasoning as audit-domains.sh
# deriving its host list from DOMAIN.md rather than restating it. A
# hardcoded list of model names would reproduce exactly the drift that
# caused this task: it would need editing every time a repo adopts or
# retires a model, and nothing would tell you it had gone stale. A shape
# does not need editing when a new model launches, as long as the provider
# keeps naming models the way it always has.
#
# ASSERTS RESOLUTION with a live call to the public Generative Language API
# (GET /v1beta/models/{id}), not a string comparison against a list of
# known-good names -- same shape as check-permissions-policy.sh:7-14 ("check
# the live response, not the presence of a string") and the alive() check in
# iac/scripts/check-gemini-keys-consistent.sh. CURL_CMD is overridable so
# the companion test is hermetic: no network, no real API key.
#
# SCOPE NOTE: this checks the public generativelanguage.googleapis.com
# surface, which is what meniapp/kidai/bass-tuner/iac's hardcoded strings
# call. second-brain's vision_*.py scripts call Vertex AI's Gemini surface
# instead (vision_sample_stratified.py:20: "gemini-3.1-flash-lite only
# resolves via locations/global"), which uses GCP service-account auth, not
# an API key, and is NOT covered by this check -- a model ID discovered
# there that 404s against the public API is reported as DRIFT even though
# it may in fact be a Vertex-only name. Said explicitly in the DRIFT line so
# a human reading the alert isn't misled into chasing the wrong repo; not
# solved here because covering Vertex needs separate per-repo GCP credential
# wiring, which is a larger change than this task.
#
# FAILS CLOSED (iac-7254 / iac-da6a precedent: assert auth first, exit a
# DISTINCT code for "cannot verify" than for "verified broken"). A missing
# or rejected API key exits 2 (CANNOT RUN) and never 0 -- it must not read
# as "every model resolves" just because nothing could actually be checked.
# A real 404/400 from the provider (the model genuinely doesn't exist)
# exits 1 (DRIFT). The two are never the same exit code, so whoever reads
# the alert (or the run-monitor.sh log) can't confuse "the credential broke"
# with "a model got retired".
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# .donefile, and any "bench"/"snapshots" dir, are excluded from scanning
# below because they hold task-title text and historical benchmark/eval
# archives, not live application config -- donefile's own
# bench/closure_dataset.json (verified live 2026-09-29, and NUL-containing:
# `grep` without `-o` or `-a` would miss it entirely and hide the very
# problem this comment is about) embeds old task filenames including
# "...-gemini-25-model-strings-hardcoded.md". That matches the shape below
# just as well as a real model string, and would alert forever since a
# task-slug is never going to resolve against the API.
#
# Structural shape of a Gemini model ID, not an enumerated list of known
# names: gemini-<major>[.<minor>]-<word>[-<word>...] (gemini-2.5-flash-image,
# gemini-3-flash-preview, gemini-3.1-flash-lite, gemini-2.5-flash-preview-tts)
# or the version-less stable aliases gemini-flash-latest / gemini-pro-latest.
# Deliberately does NOT match gemini-free-tier-2026 (a GCP project id) or
# gemini-key-mgr (a service-account name) -- neither has a digit, nor
# flash-latest/pro-latest, right after "gemini-".
MODEL_ID_REGEX='gemini-([0-9]+(\.[0-9]+)?-[a-z]+(-[a-z]+)*|(flash|pro)-latest)'

# Space- or newline-separated list of roots. Overridable so the companion
# test can point this at a throwaway fixture tree instead of the real fleet
# -- hermetic, and doesn't depend on which repos/strings happen to exist on
# the box today.
#
# Default excludes any top-level dir that is a worktree staging area
# (bass-tuner-worktrees, capacity-engine-worktrees, the generic
# /home/omri/projects/worktrees, meniapp-wt, ...): those hold per-task
# scratch checkouts on throwaway branches, not the fleet's live repos, and
# scanning them both wastes time (many stale copies of the same tree) and
# can misreport an unmerged task branch's experimental model string as
# something actually shipped. Matched on suffix/exact-name rather than one
# fixed string because this box has already grown three different spellings
# of "this is a worktree dir" (verified live 2026-09-29: *-worktrees,
# meniapp-wt, and a bare top-level "worktrees").
#
# EXTRA_ROOTS below is bt-8ce4: /home/omri/projects/*/ is one hardcoded glob,
# so anything outside it was invisible to this guard by construction -- the
# same single-root defect the board census was widened for three times
# (ce-1ff6 added ~/meni, ce-bea1 added ~/tik-api, ce-e7d7 added -L for
# symlinked subtrees). Each of these three was verified live 2026-09-29 to
# actually contain a gemini-* model string today (not speculative coverage):
# ~/meni/bin/gemini_call.py, ~/tik-api/llm/gemini.py, and
# ~/apartment/sonos/sonos.py:425. None of the three is itself a symlink or
# contains a worktree-pattern subdir, so no extra filtering is needed for
# them beyond what already applies to /home/omri/projects entries.
#
# Deliberately NOT added, decided explicitly rather than left unconsidered:
#   ~/compose      -- a live app repo, but grepped clean of every LLM-provider
#                      name (openai/anthropic/gemini/claude-*/gpt-*), not just
#                      Gemini -- it does not call an LLM at all today.
#   ~/study        -- not a live application: exam/course material
#                      (sn2526a) with no LLM-provider string anywhere in it.
# Neither is a repo this fleet ships or operates, unlike meni/tik-api/apartment.
# If either ever grows a real model call, add it here the same way.
#
# PROJECTS_GLOB_ROOT and EXTRA_ROOTS are separately overridable (not just the
# combined MODEL_SCAN_ROOTS escape hatch above) so the companion test can
# exercise this DEFAULT-CONSTRUCTION logic itself -- the worktree-suffix
# filter and the extra-roots merge -- against a throwaway fixture tree,
# rather than only ever testing the MODEL_SCAN_ROOTS bypass that skips this
# code entirely.
PROJECTS_GLOB_ROOT="${MODEL_PROJECTS_ROOT:-/home/omri/projects}"
if [[ -n "${MODEL_EXTRA_ROOTS:-}" ]]; then
  read -ra EXTRA_ROOTS <<<"$MODEL_EXTRA_ROOTS"
else
  EXTRA_ROOTS=(/home/omri/meni /home/omri/tik-api /home/omri/apartment)
fi
if [[ -n "${MODEL_SCAN_ROOTS:-}" ]]; then
  read -ra SCAN_ROOTS <<<"$MODEL_SCAN_ROOTS"
else
  SCAN_ROOTS=()
  for _d in "$PROJECTS_GLOB_ROOT"/*/; do
    _name="$(basename "$_d")"
    case "$_name" in
      *-worktrees|*-wt|worktrees) continue ;;
    esac
    SCAN_ROOTS+=("$_d")
  done
  for _d in "${EXTRA_ROOTS[@]}"; do
    [[ -d "$_d" ]] && SCAN_ROOTS+=("$_d/")
  done
  unset _d _name
fi

# Two more classes of false "discovery", both hit live scanning the real
# fleet (2026-09-29):
#   - a comment discussing a model ID as PROSE, not code: kidai's
#     spend-guard.ts:47 says outright, inside a /** */ block, 'a key like
#     "gemini-3.1-flash" would be a prefix of "gemini-3.1-flash-image"' --
#     that bare string is never assigned or called anywhere, only quoted in
#     the comment illustrating a DIFFERENT bug. Filtered by dropping lines
#     whose first non-whitespace character is a comment marker (#, //, or a
#     JSDoc/block-comment continuation *) before extracting matches -- a
#     heuristic, not a real parser, but it covers bash/python/JS/TS/JSDoc,
#     which is everything --include lists below.
#   - a *.test.* file's own deliberately-fake example strings (this script's
#     OWN companion test uses "gemini-9.9-flash-doesnotexist" as a fixture)
#     getting swept up as if they were live config the moment the test file
#     itself lands in the scanned tree. Excluded by filename/dir pattern --
#     but GNU grep applies --include/--exclude in COMMAND-LINE ORDER, last
#     match for a given file wins (verified live 2026-09-29 against the real
#     /usr/bin/grep binary, GNU grep 3.11: identical flags, only the order
#     swapped, changed the result). --exclude MUST come after --include
#     below, or --include='*.sh' re-admits a file that also matched
#     --exclude='*.test.*'.
#   - ~/meni/state/children.json (in scope once ~/meni was added to
#     EXTRA_ROOTS, bt-8ce4) is a pool of WORKER SESSION NAMES, not model
#     config -- and per this repo's own naming convention (set_identity
#     names a worker from its task title) it contains entries like
#     "two-gemini-2-5-model-str-6a02c2", whose slug-shaped digits happen to
#     match MODEL_ID_REGEX as "gemini-25-model-strings". That string will
#     never resolve against the API and isn't a model ID anyone calls --
#     exact same false-discovery class as the .donefile task-title text
#     already excluded above, just one file instead of one directory.
#     Verified live 2026-09-29: this is the only false positive introduced
#     by widening SCAN_ROOTS to ~/meni, ~/tik-api and ~/apartment.
discovered="$(
  grep -rhnE "$MODEL_ID_REGEX" \
    --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist \
    --exclude-dir=build --exclude-dir=.next --exclude-dir=__pycache__ \
    --exclude-dir=.venv --exclude-dir=venv \
    --exclude-dir=.donefile --exclude-dir=snapshots --exclude-dir=bench \
    --exclude-dir=test --exclude-dir=tests \
    --include='*.sh' --include='*.py' --include='*.ts' --include='*.tsx' \
    --include='*.js' --include='*.mjs' --include='*.json' \
    --exclude='*.test.*' --exclude='test_*' --exclude='*_test.py' \
    --exclude='children.json' \
    "${SCAN_ROOTS[@]}" 2>/dev/null \
  | grep -vE '^[0-9]+:[[:space:]]*(#|//|\*([^/]|$))' \
  | grep -oE "$MODEL_ID_REGEX" \
  | sort -u
)"

# A tiny, explicit, justified allowlist for strings that match the model-ID
# shape but are confirmed NOT to be model IDs this fleet calls -- the shape
# can't distinguish "a literal passed to the API" from "a pricing-tier bucket
# label that happens to look like one", so a per-string exception is added
# here only once actually hit and verified, the same way
# check-fleet-ci-runner-health.sh's EXCLUDE_REPOS_EXTRA works. Anything NOT
# on this list is still discovered fresh every run.
#
#   gemini-3.1-pro (vidsmith/vidsmith/cost.py:92, COST table key) -- that
#   repo's own vs-d3ef comment at cost.py:219 says outright: "gemini-2.5-pro
#   here is a pricing-tier label, not a model ID this repo calls" -- the
#   audiojudge.py model actually called is gemini-3.1-pro-preview (separately
#   discovered and verified to resolve). Confirmed live 2026-09-29: the bare
#   "gemini-3.1-pro" 404s against the API and always will, since nothing ever
#   sends it there.
#
#   gemini-2.5-flash-preview-image (bt-8ce4, ~/meni/bin/billing_killswitch.py's
#   TOKEN_USD_PER_M table, now in scope via EXTRA_ROOTS above) -- that file's
#   own "THE NAME TRAP" comment (measured 2026-09-02, just above the table)
#   says outright: calls go to models/gemini-2.5-flash-image, but Cloud
#   Monitoring labels that same traffic model=gemini-2.5-flash-preview-image,
#   and the table is deliberately keyed on the METRIC label, not the API
#   path, because keying on the API name once already priced a month at 0.00.
#   It is a metric label, never sent to the API, and will 404 forever --
#   confirmed live 2026-09-29.
MODEL_ID_IGNORE_DEFAULT="gemini-3.1-pro gemini-2.5-flash-preview-image"
IGNORE_LIST="${MODEL_ID_IGNORE:-$MODEL_ID_IGNORE_DEFAULT}"
if [[ -n "$IGNORE_LIST" ]]; then
  declare -A _ignore=()
  for _m in $IGNORE_LIST; do _ignore["$_m"]=1; done
  _filtered=""
  while IFS= read -r _m; do
    [[ -z "$_m" || -n "${_ignore[$_m]:-}" ]] && continue
    _filtered+="$_m"$'\n'
  done <<<"$discovered"
  discovered="${_filtered%$'\n'}"
  unset _ignore _m _filtered
fi

if [[ -z "$discovered" ]]; then
  echo "CANNOT RUN: discovered 0 model IDs scanning ${SCAN_ROOTS[*]} -- either the scan roots are empty or the model-ID shape regex no longer matches anything live. A silent 0-model run is exactly how this class of monitor goes blind without anyone noticing, so it is treated as a failure to run, not a clean pass." >&2
  exit 2
fi

# Resolve an API key. Direct env override first (used by the hermetic test
# and available to a human running this by hand); otherwise fetch
# MENI_TOOLS_GEMINI_API_KEY from Infisical prod the same way
# renew-wildcard-cert.sh fetches CLOUDFLARE_API_TOKEN -- meni_vps_tools is
# the box-level utility Gemini key (see
# iac/scripts/check-gemini-keys-consistent.sh's MAP), which is what a
# cross-repo VPS monitor like this one should authenticate as, not any one
# app's own per-service key.
API_KEY="${GEMINI_API_KEY:-}"
if [[ -z "$API_KEY" ]]; then
  AUTH_ENV="${MENI_AUTH_ENV:-$HOME/.meni/auth.env}"
  if [[ ! -r "$AUTH_ENV" ]]; then
    echo "CANNOT RUN: no GEMINI_API_KEY set and $AUTH_ENV not readable -- can't authenticate to Infisical for MENI_TOOLS_GEMINI_API_KEY" >&2
    exit 2
  fi
  # shellcheck disable=SC1090
  source "$AUTH_ENV"
  _infisical_token=$(curl -sf -m 30 -X POST \
    https://app.infisical.com/api/v1/auth/universal-auth/login \
    -H "Content-Type: application/json" \
    -d "{\"clientId\":\"$INFISICAL_UNIVERSAL_AUTH_CLIENT_ID\",\"clientSecret\":\"$INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET\"}" \
    | python3 -c "import json,sys; print(json.load(sys.stdin)['accessToken'])" 2>/dev/null) || true
  unset INFISICAL_UNIVERSAL_AUTH_CLIENT_ID INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET
  if [[ -z "${_infisical_token:-}" ]]; then
    echo "CANNOT RUN: Infisical login failed, can't fetch MENI_TOOLS_GEMINI_API_KEY" >&2
    exit 2
  fi
  API_KEY=$(curl -sf -m 30 \
    "https://app.infisical.com/api/v3/secrets/raw/MENI_TOOLS_GEMINI_API_KEY?workspaceId=$INFISICAL_PROJECT_ID&environment=prod&secretPath=/" \
    -H "Authorization: Bearer $_infisical_token" \
    | python3 -c "import json,sys; print(json.load(sys.stdin)['secret']['secretValue'])" 2>/dev/null) || true
  unset _infisical_token
  if [[ -z "$API_KEY" ]]; then
    echo "CANNOT RUN: MENI_TOOLS_GEMINI_API_KEY not readable from Infisical prod" >&2
    exit 2
  fi
fi

OK=() DRIFT=() CANNOT=()
while IFS= read -r model; do
  [[ -z "$model" ]] && continue
  code="$("${CURL_CMD:-curl}" -s -o /dev/null -w '%{http_code}' --max-time 15 \
    -H "x-goog-api-key: $API_KEY" \
    "https://generativelanguage.googleapis.com/v1beta/models/${model}")"
  case "$code" in
    200) OK+=("$model") ;;
    401|403) CANNOT+=("$model:$code (auth)") ;;
    404|400) DRIFT+=("$model:$code") ;;
    *) CANNOT+=("$model:$code") ;;
  esac
done <<<"$discovered"

auth_fail=0
if [[ "${#CANNOT[@]}" -gt 0 ]]; then
  for c in "${CANNOT[@]}"; do
    [[ "$c" == *"(auth)"* ]] && auth_fail=1
  done
fi

if [[ "$auth_fail" -eq 1 ]]; then
  echo "CANNOT RUN: Gemini API key rejected (401/403) checking $(( ${#OK[@]} + ${#DRIFT[@]} + ${#CANNOT[@]} )) discovered model ID(s) -- not evidence any model is retired, the credential itself is bad:" >&2
  printf '  %s\n' "${CANNOT[@]}" >&2
  exit 2
fi

if [[ "${#DRIFT[@]}" -gt 0 ]]; then
  echo "DRIFT  ${#DRIFT[@]} model ID(s) no longer resolve against the Generative Language API (a provider-side retirement, or a Vertex-only name -- see this script's SCOPE NOTE):" >&2
  printf '  %s\n' "${DRIFT[@]}" >&2
  exit 1
fi

if [[ "${#CANNOT[@]}" -gt 0 ]]; then
  echo "CANNOT RUN: ${#CANNOT[@]} model ID check(s) got an unexpected response (network failure or 5xx), not a clean pass:" >&2
  printf '  %s\n' "${CANNOT[@]}" >&2
  exit 2
fi

echo "OK     ${#OK[@]} model ID(s) resolve: ${OK[*]}"
exit 0
