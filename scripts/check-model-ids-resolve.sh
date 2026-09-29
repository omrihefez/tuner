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
if [[ -n "${MODEL_SCAN_ROOTS:-}" ]]; then
  read -ra SCAN_ROOTS <<<"$MODEL_SCAN_ROOTS"
else
  SCAN_ROOTS=()
  for _d in /home/omri/projects/*/; do
    _name="$(basename "$_d")"
    case "$_name" in
      *-worktrees|*-wt|worktrees) continue ;;
    esac
    SCAN_ROOTS+=("$_d")
  done
  unset _d _name
fi

discovered="$(
  grep -rhoE "$MODEL_ID_REGEX" \
    --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist \
    --exclude-dir=build --exclude-dir=.next --exclude-dir=__pycache__ \
    --exclude-dir=.venv --exclude-dir=venv \
    --exclude-dir=.donefile --exclude-dir=snapshots --exclude-dir=bench \
    --include='*.sh' --include='*.py' --include='*.ts' --include='*.tsx' \
    --include='*.js' --include='*.mjs' --include='*.json' \
    "${SCAN_ROOTS[@]}" 2>/dev/null \
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
MODEL_ID_IGNORE_DEFAULT="gemini-3.1-pro"
IGNORE_LIST="${MODEL_ID_IGNORE:-$MODEL_ID_IGNORE_DEFAULT}"
if [[ -n "$IGNORE_LIST" ]]; then
  discovered="$(comm -23 <(printf '%s\n' "$discovered") <(printf '%s\n' $IGNORE_LIST | sort -u))"
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
