#!/usr/bin/env bash
# bt-1af4: every host monitor in this fleet (audit-domains.sh,
# check-cert-expiry.sh, check-tunnel-liveness.sh, check-public-surfaces.sh)
# derives its host list FROM ~/meni/DOMAIN.md §1, so none of them can ever
# witness a live surface that was never added to the registry -- the
# coverage question "is every registered host watched" is answered by
# construction and always returns yes. This is the monitor that asks the
# question nothing else does: "is every LIVE host registered."
#
# `preview.meni.omrihefez.com` is why this is not theoretical: it needed no
# DNS record (the `*.omrihefez.com` wildcard answers for any name under it)
# and no Vercel project of its own (it is an ALIAS onto meni-arch), so it was
# invisible to every registry-derived monitor AND to the DNS/Vercel-project
# drift audit -- neither enumerates "names actually being served" -- and it
# accepted Omri's PRODUCTION passkey the whole time nothing watched it.
#
# DISCOVERS from the SERVING side, not from DNS -- DNS presence alone proved
# unreliable while building this: `arch-preview.omrihefez.com` still carries
# a live CNAME to cname.vercel-dns.com (measured 2026-10-13) weeks after its
# Vercel alias was removed and it started 404ing by design (DOMAIN.md row
# 26). A record-presence check would have reported it as an undiscovered
# drift forever. Two sources, each a genuine "something is configured to
# answer this name" signal:
#   1. Vercel aliases (discover_vercel_hosts) -- an alias exists only while a
#      deployment is actually mapped to the name; removing it (`vercel alias
#      rm`, the real fix for arch-preview) removes the alias too. Catches
#      the preview.meni class: no DNS record, no project-domains entry, a
#      bare alias.
#   2. Cloudflare CNAME records whose content resolves into a live
#      `*.cfargotunnel.com` tunnel (discover_tunnel_hosts) -- the
#      non-Vercel/tunnel-fronted hosts (house, oauth, brain, meniapp-api,
#      tik-api, tik-api-vps), none of which ever get a Vercel alias. A CNAME
#      pointed at the generic `cname.vercel-dns*.com` target is NOT treated
#      as live here -- that is the exact shape of the stale arch-preview
#      record and is indistinguishable from the wildcard's own target by
#      content alone, so it is deliberately excluded rather than trusted.
#      This also means ordinary email-infra CNAMEs (`links` -> Resend) are
#      correctly ignored: they don't end in .cfargotunnel.com either.
#
# DIFFS the union of both against derive_registry_hosts(DOMAIN.md, "all")
# (🟢 live / 🔵 alias rows) and fails on anything live-but-unregistered.
# Deliberately does NOT re-implement the "is every registered host watched"
# direction -- that is audit-domains.sh / check-tunnel-liveness.sh's job and
# answering it again here would just reproduce the by-construction trap this
# task exists to fix, the other way round.
#
# FAILS CLOSED, same convention as check-model-ids-resolve.sh (bt-5abe) and
# check-permissions-policy.sh: a failed/unparseable fetch from either source,
# or deriving zero hosts from either side, is CANNOT RUN (exit 2) and must
# never be read as "nothing live, nothing unregistered."
#   exit 0 -- OK, every discovered live host has a registry row
#   exit 1 -- DRIFT, at least one live host has no registry row
#   exit 2 -- CANNOT RUN, discovery itself failed
#
# Overrides (same CURL_CMD-stub convention as every monitor in this repo, so
# the companion .test.sh needs no network, no Vercel session and no
# Cloudflare/Infisical credential):
#   VERCEL_ALIAS_CMD      replaces the full `vercel alias list --format json
#                         --limit 100` invocation; `--next <cursor>` is
#                         appended automatically whenever one is paginating.
#   VERCEL_ALIAS_MAX_PAGES  pagination safety cap (default 200) -- the real
#                         fleet measured 4 pages / 371 aliases live
#                         2026-10-13, so 200 is headroom, not a tight budget;
#                         exceeding it is CANNOT RUN, not an infinite loop.
#   CF_DNS_RECORDS_CMD    replaces the entire Infisical-login +
#                         Cloudflare-API-fetch pipeline with one command that
#                         prints the zone's `GET .../dns_records?type=CNAME`
#                         JSON body on stdout.
#   CF_ZONE_ID            zone id for the real fetch path (default: the one
#                         live zone, same constant renew-wildcard-cert.sh
#                         already hardcodes).
#   DOMAIN_MD             registry path (default $HOME/meni/DOMAIN.md), same
#                         convention as every other monitor here.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/domain-registry.sh
. "$HERE/lib/domain-registry.sh" || {
  echo "FATAL: cannot source lib/domain-registry.sh -- refusing to run with no derived host list" >&2
  exit 2
}

VERCEL_ALIAS_MAX_PAGES="${VERCEL_ALIAS_MAX_PAGES:-200}"

# _vercel_alias_page <cursor> -- prints one "HOST\t<alias>" line per
# omrihefez.com alias on this page, followed by exactly one "NEXT\t<cursor>"
# line (cursor empty when there is no further page). Returns non-zero on any
# fetch/parse failure so the caller can fail closed.
_vercel_alias_page() {
  local cursor="$1"
  local -a cmd
  if [ -n "${VERCEL_ALIAS_CMD:-}" ]; then
    read -r -a cmd <<<"$VERCEL_ALIAS_CMD"
  else
    cmd=(vercel alias list --format json --limit 100)
  fi
  [ -n "$cursor" ] && cmd+=(--next "$cursor")
  local out
  out="$("${cmd[@]}" 2>/dev/null)" || return 2
  printf '%s' "$out" | python3 -c '
import json, sys
raw = sys.stdin.read()
i = raw.find("{")
if i < 0:
    sys.exit(3)
try:
    d = json.loads(raw[i:])
except Exception:
    sys.exit(3)
for a in d.get("aliases", []):
    al = a.get("alias", "")
    if al.endswith(".omrihefez.com"):
        print("HOST\t" + al)
nxt = (d.get("pagination") or {}).get("next")
print("NEXT\t" + (str(nxt) if nxt else ""))
'
}

# discover_vercel_hosts -- prints one bare label (no .omrihefez.com suffix)
# per line for every live Vercel alias, paginating until exhausted.
discover_vercel_hosts() {
  local cursor="" page=0 out rc
  while :; do
    page=$((page + 1))
    if [ "$page" -gt "$VERCEL_ALIAS_MAX_PAGES" ]; then
      echo "CANNOT RUN: vercel alias pagination did not terminate within $VERCEL_ALIAS_MAX_PAGES pages" >&2
      return 2
    fi
    out="$(_vercel_alias_page "$cursor")"
    rc=$?
    if [ "$rc" -ne 0 ] || [ -z "$out" ]; then
      echo "CANNOT RUN: vercel alias list failed or returned unparseable JSON (page $page, exit $rc)" >&2
      return 2
    fi
    cursor=""
    while IFS=$'\t' read -r kind val; do
      case "$kind" in
        HOST) echo "${val%.omrihefez.com}" ;;
        NEXT) cursor="$val" ;;
      esac
    done <<<"$out"
    [ -n "$cursor" ] || break
  done
}

# _fetch_cloudflare_cname_records -- the real (non-test) path: logs into
# Infisical via the meni-runtime machine identity and fetches
# CLOUDFLARE_API_TOKEN, exactly the pattern scripts/renew-wildcard-cert.sh
# already uses for this zone, then GETs the zone's CNAME records. Prints the
# raw Cloudflare API JSON body on stdout.
_fetch_cloudflare_cname_records() {
  local zone_id="${CF_ZONE_ID:-e8f56b4957a31cc5e80940cd45470440}"
  if [[ ! -r "$HOME/.meni/auth.env" ]]; then
    echo "CANNOT RUN: $HOME/.meni/auth.env not readable, can't authenticate to Infisical" >&2
    return 2
  fi
  # shellcheck disable=SC1091
  source "$HOME/.meni/auth.env"
  local itok
  itok=$(curl -sf -m 30 -X POST \
    https://app.infisical.com/api/v1/auth/universal-auth/login \
    -H "Content-Type: application/json" \
    --data @<(printf '{"clientId":"%s","clientSecret":"%s"}' "$INFISICAL_UNIVERSAL_AUTH_CLIENT_ID" "$INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET") \
    | python3 -c "import json,sys; print(json.load(sys.stdin)['accessToken'])" 2>/dev/null) || true
  unset INFISICAL_UNIVERSAL_AUTH_CLIENT_ID INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET
  if [[ -z "$itok" ]]; then
    echo "CANNOT RUN: Infisical login failed, can't get CLOUDFLARE_API_TOKEN" >&2
    return 2
  fi
  local cftok
  cftok=$(curl -sf -m 30 \
    --config <(printf 'header = "Authorization: Bearer %s"\n' "$itok") \
    "https://app.infisical.com/api/v3/secrets/raw/CLOUDFLARE_API_TOKEN?workspaceId=$INFISICAL_PROJECT_ID&environment=prod&secretPath=/" \
    | python3 -c "import json,sys; print(json.load(sys.stdin)['secret']['secretValue'])" 2>/dev/null) || true
  unset itok
  if [[ -z "$cftok" ]]; then
    echo "CANNOT RUN: CLOUDFLARE_API_TOKEN not readable from Infisical prod" >&2
    return 2
  fi
  local body rc
  body="$(curl -sf -m 30 \
    --config <(printf 'header = "Authorization: Bearer %s"\n' "$cftok") \
    "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records?type=CNAME&per_page=200")"
  rc=$?
  unset cftok
  if [ "$rc" -ne 0 ]; then
    echo "CANNOT RUN: Cloudflare DNS records fetch failed (exit $rc)" >&2
    return 2
  fi
  printf '%s' "$body"
}

# discover_tunnel_hosts -- prints one bare label per line for every CNAME in
# the zone whose content is a live `*.cfargotunnel.com` tunnel target. A
# generic `cname.vercel-dns*.com` target (what a stale, alias-removed record
# like arch-preview's still carries) is deliberately NOT treated as live --
# see the file header.
discover_tunnel_hosts() {
  local out rc
  if [ -n "${CF_DNS_RECORDS_CMD:-}" ]; then
    out="$(eval "$CF_DNS_RECORDS_CMD" 2>/dev/null)"
    rc=$?
  else
    out="$(_fetch_cloudflare_cname_records)"
    rc=$?
  fi
  if [ "$rc" -ne 0 ] || [ -z "$out" ]; then
    echo "CANNOT RUN: Cloudflare CNAME discovery failed (exit $rc)" >&2
    return 2
  fi
  printf '%s' "$out" | python3 -c '
import json, sys
raw = sys.stdin.read()
try:
    d = json.loads(raw)
except Exception:
    sys.exit(3)
if not d.get("success", False):
    sys.exit(3)
suffix = ".omrihefez.com"
for r in d.get("result", []):
    if r.get("type") != "CNAME":
        continue
    name = r.get("name", "")
    content = r.get("content", "")
    if name == "*" + suffix:
        continue
    if name.endswith(suffix) and content.endswith(".cfargotunnel.com"):
        print(name[: -len(suffix)])
'
  rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "CANNOT RUN: Cloudflare DNS records response was unparseable or unsuccessful" >&2
    return 2
  fi
}

DOMAIN_MD="${DOMAIN_MD:-$HOME/meni/DOMAIN.md}"
[ -r "$DOMAIN_MD" ] || {
  echo "FATAL: cannot read $DOMAIN_MD -- refusing to run with no registry" >&2
  exit 2
}

mapfile -t REGISTERED < <(derive_registry_hosts "$DOMAIN_MD" all 2>/dev/null | sort -u)
if [ "${#REGISTERED[@]}" -eq 0 ]; then
  echo "FATAL: derived zero registered live/alias hosts from $DOMAIN_MD -- refusing to run with an empty registry" >&2
  exit 2
fi
declare -A REG_SET=()
for h in "${REGISTERED[@]}"; do
  [ -n "$h" ] && REG_SET["$h"]=1
done

vercel_out="$(discover_vercel_hosts)"
vrc=$?
if [ "$vrc" -ne 0 ]; then
  exit 2
fi
mapfile -t VERCEL_LIVE <<<"$vercel_out"

tunnel_out="$(discover_tunnel_hosts)"
trc=$?
if [ "$trc" -ne 0 ]; then
  exit 2
fi
mapfile -t TUNNEL_LIVE <<<"$tunnel_out"

declare -A LIVE_SOURCE=()
for h in "${VERCEL_LIVE[@]}"; do
  [ -n "$h" ] || continue
  if [ -n "${LIVE_SOURCE[$h]:-}" ]; then
    LIVE_SOURCE["$h"]="${LIVE_SOURCE[$h]},vercel-alias"
  else
    LIVE_SOURCE["$h"]="vercel-alias"
  fi
done
for h in "${TUNNEL_LIVE[@]}"; do
  [ -n "$h" ] || continue
  if [ -n "${LIVE_SOURCE[$h]:-}" ]; then
    LIVE_SOURCE["$h"]="${LIVE_SOURCE[$h]},cloudflare-tunnel"
  else
    LIVE_SOURCE["$h"]="cloudflare-tunnel"
  fi
done

if [ "${#LIVE_SOURCE[@]}" -eq 0 ]; then
  echo "FATAL: discovered zero live hosts from either Vercel aliases or Cloudflare tunnel CNAMEs -- refusing to run an empty check" >&2
  exit 2
fi

FAIL=0
while IFS= read -r h; do
  [ -n "$h" ] || continue
  if [ -z "${REG_SET[$h]:-}" ]; then
    echo "DRIFT  $h.omrihefez.com -> live via ${LIVE_SOURCE[$h]} but has no DOMAIN.md §1 row (🟢/🔵) -- add a registry row"
    FAIL=1
  else
    echo "OK     $h.omrihefez.com -> live via ${LIVE_SOURCE[$h]}, registered"
  fi
done < <(printf '%s\n' "${!LIVE_SOURCE[@]}" | sort -u)

exit "$FAIL"
