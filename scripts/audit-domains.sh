#!/usr/bin/env bash
# Audit real omrihefez.com app subdomains for the bt-417b class of drift:
# DNS/wildcard resolves to Vercel, but the domain was never added to any
# Vercel project -> Deployment Protection gates it, redirecting to
# vercel.com/login instead of serving the app.
#
# HOST LIST (ma-20c5): derived at RUNTIME from ~/meni/DOMAIN.md §1 via
# scripts/lib/domain-registry.sh, not a hand-copied array — the array
# previously drifted to 8 hosts against a registry of 11 live/alias rows,
# missing `meniapp` entirely (a real gap: it IS Vercel + live, so it should
# always have been checked here).
#
# Only §1 rows with Status 🟢 live / 🔵 alias AND Host containing "Vercel"
# enter the Deployment-Protection check below — that check is meaningless
# for a Cloudflare-Tunnel-fronted host (`meniapp-api`, `tik-api`: their
# normal `/` response is a bare 404, not a Vercel app page or a redirect;
# verified live 2026-08-18). Those are printed as an explicit SKIP line, not
# silently dropped — and because the split is derived from the registry's
# own Host column rather than a hardcoded exclusion list, a *new*
# non-Vercel live host is automatically SKIPped and named too, instead of
# either crashing this script or silently vanishing the way the old
# 8-vs-11 gap did.
#
# AUDIT_SUBS (space-separated bare labels, no .omrihefez.com suffix) skips
# the DOMAIN.md derivation entirely and checks exactly that list instead —
# same env-override convention as check-cert-expiry.sh's CERT_HOSTS. Used by
# audit-domains.test.sh and by scripts/test-monitoring.sh's bt-a942 self-test
# (which forces a failure by pointing this at a nonexistent host, in place
# of the old sed-patch against a literal `SUBS=` line this script no longer
# has).
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/domain-registry.sh
. "$HERE/lib/domain-registry.sh" || {
  echo "FATAL: cannot source lib/domain-registry.sh — refusing to run with no derived host list" >&2
  exit 2
}

OTHER_LIVE=()
if [ -n "${AUDIT_SUBS:-}" ]; then
  read -r -a SUBS <<<"$AUDIT_SUBS"
else
  DOMAIN_MD="${DOMAIN_MD:-$HOME/meni/DOMAIN.md}"
  [ -r "$DOMAIN_MD" ] || {
    echo "FATAL: cannot read $DOMAIN_MD — refusing to run an audit with no registry" >&2
    exit 2
  }
  mapfile -t SUBS < <(derive_registry_hosts "$DOMAIN_MD" vercel | sort -u)
  mapfile -t OTHER_LIVE < <(derive_registry_hosts "$DOMAIN_MD" non-vercel | sort -u)
fi

if [ "${#SUBS[@]}" -eq 0 ]; then
  echo "FATAL: derived zero Vercel-hosted live/alias subdomains — refusing to run an empty audit" >&2
  exit 2
fi

FAIL=0

for h in "${OTHER_LIVE[@]}"; do
  echo "SKIP   $h.omrihefez.com -> live in the registry but not Vercel-hosted; Deployment-Protection drift does not apply"
done

for d in "${SUBS[@]}"; do
  host="$d.omrihefez.com"
  resp=$("${CURL_CMD:-curl}" -s -D - -o /dev/null --max-time 10 "https://$host/")
  code=$(echo "$resp" | head -1 | awk '{print $2}')
  loc=$(echo "$resp" | grep -i '^location:' | tr -d '\r')

  if echo "$loc" | grep -qi 'vercel\.com'; then
    echo "DRIFT  $host -> $code $loc"
    FAIL=1
  elif [[ "$code" == "200" || "$code" == "307" || "$code" == "401" || "$code" == "308" ]]; then
    echo "OK     $host -> $code ${loc:+($loc)}"
  else
    echo "CHECK  $host -> $code ${loc:+($loc)}"
    FAIL=1
  fi
done

exit $FAIL
