#!/usr/bin/env bash
# Verify the Vercel fallback TLS cert for unclaimed omrihefez.com subdomains
# is valid (bt-2b10). An unclaimed subdomain (DNS resolves to Vercel via the
# *.omrihefez.com wildcard, but no project has attached that domain) must
# still complete a valid TLS handshake and return a clean 404, never a hard
# TLS failure. Uses composer.omrihefez.com, a known-phantom subdomain
# (~/meni/DOMAIN.md: "no Vercel project + no DNS record").
set -uo pipefail

HOST="composer.omrihefez.com"

if ! resp=$(curl -sI --max-time 10 "https://$HOST/" 2>&1); then
  echo "FAIL   $HOST TLS/connection error:"
  echo "$resp"
  exit 1
fi

code=$(echo "$resp" | head -1 | awk '{print $2}')
if [[ "$code" == "404" ]]; then
  echo "OK     $HOST -> $code (clean fallback 404, cert valid)"
  exit 0
else
  echo "CHECK  $HOST -> $code (expected 404)"
  echo "$resp"
  exit 1
fi
