#!/usr/bin/env bash
# Audit real omrihefez.com app subdomains for the bt-417b class of drift:
# DNS/wildcard resolves to Vercel, but the domain was never added to any
# Vercel project -> Deployment Protection gates it, redirecting to
# vercel.com/login instead of serving the app.
#
# Source of truth for "real" subdomains: ~/meni/DOMAIN.md section 1
# (rows with Host=Vercel and Status=live). tik-api is excluded: it's
# fronted by a Cloudflare Tunnel, not Vercel.
set -uo pipefail

SUBS=(albumclub bass compose kidai meni planner tik trips tuner)
FAIL=0

for d in "${SUBS[@]}"; do
  host="$d.omrihefez.com"
  resp=$(curl -s -D - -o /dev/null --max-time 10 "https://$host/")
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
