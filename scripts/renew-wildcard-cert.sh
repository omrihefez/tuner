#!/usr/bin/env bash
# Non-interactive renewal for the Vercel wildcard cert (*.omrihefez.com).
#
# Why this exists (bt-03ea): DNS for omrihefez.com lives on Cloudflare
# nameservers, not Vercel's, so Vercel's automatic DNS-01 renewal can't place
# the _acme-challenge TXT record itself -- the wildcard cert silently expired
# once already. This script closes that gap: it drives `vercel certs issue`
# through the DNS-01 challenge itself, writing the TXT record via the
# Cloudflare API (token from Infisical prod `CLOUDFLARE_API_TOKEN`, see
# ~/meni/DOMAIN.md and the vault-fetch block below), so the whole
# renewal needs no human in the loop.
#
# Usage:
#   scripts/renew-wildcard-cert.sh                        # only acts if the
#                                            # cert is within RENEW_THRESHOLD_DAYS
#                                            # of expiry
#   scripts/renew-wildcard-cert.sh --force                # print what a forced
#                                            # renewal would do and exit --
#                                            # touches nothing (bt-4923)
#   scripts/renew-wildcard-cert.sh --force --i-mean-it     # actually renew
#                                            # right now regardless of current
#                                            # expiry (used to prove the flow
#                                            # end-to-end, and as an escape
#                                            # hatch if it ever expires)
#
# bt-4923: --force alone used to perform live ACME issuance and Cloudflare DNS
# writes immediately, with no confirmation -- a debugging session passed
# --force just to test a PATH fix and silently issued a real cert, then left
# an orphaned _acme-challenge TXT record when a second run was killed
# mid-flight. --force now only prints what it would do; --i-mean-it is the
# explicit opt-in required to actually touch Cloudflare/Vercel.
#
# Intended to run from cron (see scripts/install-cert-renewal-cron.sh), which
# never passes --force -- cron always goes through the threshold check above.
set -uo pipefail

# bt-a428: cron runs with a minimal PATH that doesn't include ~/.bun/bin,
# where the vercel CLI actually lives (bun-installed global) -- without it
# the scheduled run dies on `vercel: command not found` and the cert never
# renews (same fix already applied to meniapp's deploy-app-if-changed.sh for
# the same reason). node itself resolves fine under cron's default PATH
# (/usr/bin/node), so only the bun bin dir needs adding here.
export PATH="$HOME/.bun/bin:$PATH"

CN='*.omrihefez.com'
ZONE_ID=e8f56b4957a31cc5e80940cd45470440
RECORD_NAME=_acme-challenge.omrihefez.com

# bt-cd2d: weekly cron + this threshold gives a worst-case gap of only
# ~3 days over Vercel's own ~21d-ish auto-renew window (skip at 31d left,
# next weekly check 7d later at 24d left) -- one missed cron run and that
# gap is gone. 45d gives ~18d of worst-case margin, and survives a single
# missed weekly run (45-14=31d, still well clear of 21d).
RENEW_THRESHOLD_DAYS=45
FORCE=0
CONFIRMED=0
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    --i-mean-it) CONFIRMED=1 ;;
  esac
done

log() { echo "[$(date -u +%FT%TZ)] $*"; }

# bt-6791: a plain substring match for "success" also matches "unsuccessful",
# so "Certificate issuance was unsuccessful" set issue_ok=1. Anchored on
# non-letter boundaries so it can't match inside a longer word either
# direction (unsuccessful, successfully-ish, etc).
issuance_reports_success() {
  local exit_code="$1" output="$2"
  [[ "$exit_code" -eq 0 ]] || return 1
  printf '%s' "$output" | grep -qiE '(^|[^[:alpha:]])success(ful(ly)?)?([^[:alpha:]]|$)'
}

# Sourced by the test file, not executed standalone -- stop here so the real
# renewal flow (secrets fetch, DNS writes, ACME issuance) never runs under test.
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
  return 0
fi

# bt-4923: --force alone is a dry-run description, not an action -- it must
# require --i-mean-it too, so that a debugging/testing invocation using
# --force to reach later code (e.g. to test a PATH fix) can't accidentally
# perform a live ACME issuance or Cloudflare DNS write. Checked before the
# secrets file is even read, so an unconfirmed --force touches nothing.
if [[ "$FORCE" -eq 1 && "$CONFIRMED" -ne 1 ]]; then
  log "--force passed without --i-mean-it: this would renew $CN right now" \
    "regardless of current expiry -- deleting/creating live $RECORD_NAME TXT" \
    "records via the Cloudflare API and calling 'vercel certs issue $CN'."
  log "Not touching Cloudflare or Vercel. Re-run with: --force --i-mean-it"
  exit 0
fi

# bt-ed7f: refuse to run from a dirty checkout. cron execs whatever this FILE
# currently contains on disk, not what's committed -- so an uncommitted edit
# sitting in this checkout (someone mid-editing the script) would run for
# real on the next weekly tick: real Cloudflare DNS writes and a real ACME
# cert issuance, driven by whatever half-finished logic happened to be on
# disk. Same hole ce-0bda fixed for capacity-engine's dispatcher tick, same
# guard shape as second-brain's prune-fleet-worktrees.sh (ce-e338). Checked
# before secrets are even read, so a dirty checkout touches nothing --
# including on the --force --i-mean-it path, which reaches this same check.
SELF_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
dirty="$(git -C "$SELF_REPO_ROOT" status --porcelain -- . ':(exclude).donefile' ':(exclude)BOARD.md' 2>/dev/null)"
if [[ -n "$dirty" ]]; then
  log "FATAL: $SELF_REPO_ROOT has uncommitted non-bookkeeping changes -- refusing to run" \
    "(this script execs whatever is on disk, not what's committed; someone is mid-edit)."
  printf '%s\n' "$dirty" | sed 's/^/  /' >&2
  exit 1
fi

# The token comes from Infisical prod (secret CLOUDFLARE_API_TOKEN), fetched via
# the meni-runtime machine identity in ~/.meni/auth.env -- same pattern as
# iac/scripts/lib/with-cloudflare-sa.sh.
#
# There is deliberately NO fallback to a file on disk. This used to source
# ~/meni/secrets/.env, and that plaintext copy went stale and dead without
# anyone noticing, because a fallback keeps the script "working" off whatever
# is on disk and hides the drift. If the vault is unreachable, this must fail
# loudly rather than reach for a local copy.
if [[ ! -r "$HOME/.meni/auth.env" ]]; then
  log "FATAL: $HOME/.meni/auth.env not readable, can't authenticate to Infisical"
  exit 1
fi
# shellcheck disable=SC1091
source "$HOME/.meni/auth.env"

_infisical_token=$(curl -sf -m 30 -X POST \
  https://app.infisical.com/api/v1/auth/universal-auth/login \
  -H "Content-Type: application/json" \
  -d "{\"clientId\":\"$INFISICAL_UNIVERSAL_AUTH_CLIENT_ID\",\"clientSecret\":\"$INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET\"}" \
  | python3 -c "import json,sys; print(json.load(sys.stdin)['accessToken'])") || true
unset INFISICAL_UNIVERSAL_AUTH_CLIENT_ID INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET
if [[ -z "${_infisical_token:-}" ]]; then
  log "FATAL: Infisical login failed, can't get CLOUDFLARE_API_TOKEN"
  exit 1
fi

export CLOUDFLARE_API_TOKEN
CLOUDFLARE_API_TOKEN=$(curl -sf -m 30 \
  --config <(printf 'header = "Authorization: Bearer %s"\n' "$_infisical_token") \
  "https://app.infisical.com/api/v3/secrets/raw/CLOUDFLARE_API_TOKEN?workspaceId=$INFISICAL_PROJECT_ID&environment=prod&secretPath=/" \
  | python3 -c "import json,sys; print(json.load(sys.stdin)['secret']['secretValue'])") || true
unset _infisical_token
if [[ -z "${CLOUDFLARE_API_TOKEN:-}" ]]; then
  log "FATAL: CLOUDFLARE_API_TOKEN not readable from Infisical prod"
  exit 1
fi

cf() {
  # cf METHOD PATH [JSON_BODY]
  local method="$1" path="$2" body="${3:-}"
  if [[ -n "$body" ]]; then
    curl -sS -X "$method" "https://api.cloudflare.com/client/v4$path" \
      --config <(printf 'header = "Authorization: Bearer %s"\n' "$CLOUDFLARE_API_TOKEN") \
      -H "Content-Type: application/json" \
      --data "$body"
  else
    curl -sS -X "$method" "https://api.cloudflare.com/client/v4$path" \
      --config <(printf 'header = "Authorization: Bearer %s"\n' "$CLOUDFLARE_API_TOKEN")
  fi
}

if [[ "$FORCE" -ne 1 ]]; then
  # `vercel certs ls` prints one row per cert; find the wildcard's "expiration"
  # column ("in 88d" style). Skip renewal unless it's due soon.
  #
  # bt-6791: stderr used to be discarded here, so a dead Vercel credential
  # (df-0733: the CLI's token lives ~8h and only an interactive device code
  # revives it once dead) surfaced as an unparseable "days-until-expiry"
  # instead of as the auth failure it actually was -- the script then
  # proceeded into a renewal attempt that could not work. Capture both
  # streams so the real cause reaches the log, and treat a non-zero exit as
  # the auth/CLI failure it is: exit non-zero so run-monitor alerts instead
  # of limping into a doomed renewal.
  certs_ls_out=$(vercel certs ls --non-interactive 2>&1)
  certs_ls_exit=$?
  days_left=$(printf '%s\n' "$certs_ls_out" \
    | awk -v cn="$CN" '$0 ~ cn {for(i=1;i<=NF;i++) if ($i ~ /^in$/) print $(i+1)}' \
    | head -1 | tr -dc '0-9')
  if [[ "$certs_ls_exit" -ne 0 ]]; then
    log "FATAL: 'vercel certs ls' exited $certs_ls_exit -- likely a dead Vercel credential (see df-0733), refusing to proceed into a renewal that cannot work"
    printf '%s\n' "$certs_ls_out" | sed 's/^/  /' >&2
    exit 1
  fi
  if [[ -z "$days_left" ]]; then
    log "WARN: 'vercel certs ls' exited 0 but days-until-expiry for $CN didn't parse; proceeding to renew to be safe"
    printf '%s\n' "$certs_ls_out" | sed 's/^/  /' >&2
  elif (( days_left > RENEW_THRESHOLD_DAYS )); then
    log "OK: $CN has ${days_left}d left (> ${RENEW_THRESHOLD_DAYS}d threshold), nothing to do"
    exit 0
  else
    log "$CN has ${days_left}d left (<= ${RENEW_THRESHOLD_DAYS}d threshold), renewing"
  fi
else
  log "--force --i-mean-it passed, renewing $CN now regardless of current expiry"
fi

log "requesting ACME DNS-01 challenge from Vercel for $CN"
challenge_out=$(vercel certs issue "$CN" --challenge-only --non-interactive 2>&1)
echo "$challenge_out"
challenge_value=$(echo "$challenge_out" | awk '$1 == "_acme-challenge" && $2 == "TXT" {print $3}' | head -1)
if [[ -z "$challenge_value" ]]; then
  log "FATAL: could not parse challenge TXT value from vercel output above"
  exit 1
fi
log "challenge value: $challenge_value"

log "removing any stale $RECORD_NAME TXT record(s)"
existing_ids=$(cf GET "/zones/$ZONE_ID/dns_records?type=TXT&name=$RECORD_NAME" \
  | python3 -c "import json,sys;[print(r['id']) for r in json.load(sys.stdin).get('result',[])]")
for id in $existing_ids; do
  cf DELETE "/zones/$ZONE_ID/dns_records/$id" >/dev/null
  log "deleted stale record $id"
done

log "creating $RECORD_NAME TXT record with the new challenge value"
create_resp=$(cf POST "/zones/$ZONE_ID/dns_records" \
  "{\"type\":\"TXT\",\"name\":\"$RECORD_NAME\",\"content\":\"$challenge_value\",\"ttl\":60}")
new_id=$(echo "$create_resp" | python3 -c "import json,sys;d=json.load(sys.stdin);print(d['result']['id'] if d.get('success') else '')")
if [[ -z "$new_id" ]]; then
  log "FATAL: failed to create TXT record: $create_resp"
  exit 1
fi
log "created record $new_id"

log "waiting for DNS propagation (public resolver, up to 3min)"
propagated=0
for _ in $(seq 1 18); do
  seen=$(dig +short TXT "$RECORD_NAME" @1.1.1.1 2>/dev/null | tr -d '"')
  if [[ "$seen" == "$challenge_value" ]]; then
    propagated=1
    break
  fi
  sleep 10
done
if [[ "$propagated" -ne 1 ]]; then
  log "FATAL: TXT record did not propagate to 1.1.1.1 within 3min (saw: '$seen')"
  exit 1
fi
log "propagated"

log "completing certificate issuance"
issue_out=$(vercel certs issue "$CN" --non-interactive 2>&1)
issue_exit=$?
echo "$issue_out"
issue_ok=0
if issuance_reports_success "$issue_exit" "$issue_out"; then
  issue_ok=1
fi
if [[ "$issue_ok" -ne 1 ]]; then
  log "FATAL: issuance did not report success, leaving TXT record in place for inspection"
  exit 1
fi
log "issuance succeeded"

log "cleaning up challenge TXT record"
cf DELETE "/zones/$ZONE_ID/dns_records/$new_id" >/dev/null
log "done"
