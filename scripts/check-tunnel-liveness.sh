#!/usr/bin/env bash
# bt-8818: liveness check for the non-Vercel (Cloudflare-Tunnel-fronted)
# hosts that scripts/audit-domains.sh deliberately SKIPs.
#
# audit-domains.sh's `vercel` filter on derive_registry_hosts() is correct
# for what THAT script checks (Deployment-Protection drift + security
# headers -- meaningless for a tunnel origin whose normal response is a bare
# 404 or a 307 to its own login, not a Vercel app page). But nothing else in
# the estate picked up the hosts it SKIPs, so "not a Vercel host" had quietly
# become "not monitored" -- oauth.omrihefez.com (the code-pickup endpoint for
# Meni's own OAuth consents) and tik-api-vps.omrihefez.com (the tik-api
# rollback pair) had zero liveness coverage anywhere on this box. The `pete`
# row in DOMAIN.md is what an unmonitored tunnel origin going dark looks
# like: deleted underneath its DNS record, 530 for about a day before anyone
# noticed.
#
# HOST LIST: derived at runtime from ~/meni/DOMAIN.md via the same
# lib/domain-registry.sh derive_registry_hosts() audit-domains.sh uses, mode
# "non-vercel" -- the exact complement of what that script checks. Not a
# hand-typed array (the check-public-surfaces.sh mistake this repo was told
# not to repeat, df-78db) -- a new tunnel surface shows up here automatically
# the moment it's added to the registry as 🟢/🔵.
#
# EXPECTED STATUS: pinned per host (same idiom as check-public-surfaces.sh),
# not a blanket non-5xx rule -- a blanket rule would pass a completely broken
# deployment that 404s every route. A host the registry derives but that has
# no entry in EXPECT_STATUS below is NOT silently skipped: it fails loudly,
# naming itself, so "I forgot to pin the new host" is a red run instead of a
# monitoring gap nobody notices (the exact failure mode this task exists to
# close).
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/domain-registry.sh
. "$HERE/lib/domain-registry.sh" || {
  echo "FATAL: cannot source lib/domain-registry.sh — refusing to run with no derived host list" >&2
  exit 2
}

# Path checked per host and the status it is KNOWN to answer with there,
# measured live 2026-09-16:
#   oauth        /health -> 200  (DOMAIN.md names this the liveness probe;
#                                  `/` 404s -- stdlib http.server, no index route)
#   tik-api-vps  /       -> 404  (bare JSON 404 = origin responding, per
#                                  DOMAIN.md's own note on this host)
#   tik-api      /health -> 200  (already covered in health-registry.json
#                                  too; included here because it's a live
#                                  non-Vercel registry host like the rest --
#                                  duplicate coverage across independent
#                                  monitors is not a defect)
#   house        /       -> 307  (passkey redirect to its own /login)
#   brain        /       -> 404  (by-design auth wall, no index route)
#   meniapp-api  /health -> 200
declare -A EXPECT_PATH=(
  [oauth]=/health
  [tik-api-vps]=/
  [tik-api]=/health
  [house]=/
  [brain]=/
  [meniapp-api]=/health
)
declare -A EXPECT_STATUS=(
  [oauth]=200
  [tik-api-vps]=404
  [tik-api]=200
  [house]=307
  [brain]=404
  [meniapp-api]=200
)

if [ -n "${TUNNEL_HOSTS:-}" ]; then
  read -r -a HOSTS <<<"$TUNNEL_HOSTS"
else
  DOMAIN_MD="${DOMAIN_MD:-$HOME/meni/DOMAIN.md}"
  [ -r "$DOMAIN_MD" ] || {
    echo "FATAL: cannot read $DOMAIN_MD — refusing to run a liveness check with no registry" >&2
    exit 2
  }
  mapfile -t HOSTS < <(derive_registry_hosts "$DOMAIN_MD" non-vercel | sort -u)
fi

if [ "${#HOSTS[@]}" -eq 0 ]; then
  echo "FATAL: derived zero non-Vercel live/alias hosts — refusing to run an empty check" >&2
  exit 2
fi

FAIL=0

for h in "${HOSTS[@]}"; do
  host="$h.omrihefez.com"
  path="${EXPECT_PATH[$h]:-}"
  want="${EXPECT_STATUS[$h]:-}"
  if [ -z "$path" ] || [ -z "$want" ]; then
    echo "UNPINNED $host -> registry lists this as live and non-Vercel but nobody pinned an expected path/status for it in this script — add EXPECT_PATH[$h]/EXPECT_STATUS[$h]" >&2
    FAIL=1
    continue
  fi
  code=$("${CURL_CMD:-curl}" -s -o /dev/null -w '%{http_code}' --max-time 15 "https://$host$path" 2>/dev/null)
  if [ "$code" = "000" ]; then
    echo "DOWN     $host$path — no response (DNS, TLS or connection failure)" >&2
    FAIL=1
  elif [ "$code" = "$want" ]; then
    echo "ok       $host$path — HTTP $code"
  else
    echo "CHANGED  $host$path — HTTP $code, expected $want" >&2
    FAIL=1
  fi
done

if [ "$FAIL" -eq 0 ]; then
  echo "check-tunnel-liveness: all ${#HOSTS[@]} non-Vercel live hosts answering as pinned"
  exit 0
fi
echo "check-tunnel-liveness: at least one non-Vercel live host is down, drifted or unpinned" >&2
exit 1
