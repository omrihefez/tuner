#!/usr/bin/env bash
# Verify the Vercel fallback TLS cert for unclaimed omrihefez.com subdomains
# is valid (bt-2b10) AND has enough lead time before it expires (bt-b130).
# An unclaimed subdomain (DNS resolves to Vercel via the *.omrihefez.com
# wildcard, but no project has attached that domain) must still complete a
# valid TLS handshake and return a clean 404, never a hard TLS failure. Uses
# composer.omrihefez.com, a known-phantom subdomain (~/meni/DOMAIN.md: "no
# Vercel project + no DNS record").
#
# bt-b130: the clean-404 check above is a liveness check, not an expiry
# check -- it only goes red once the handshake is ALREADY failing, at the
# moment an outage starts, with zero lead time. That is exactly the failure
# this file exists because of: the wildcard cert expired silently on
# 2026-06-17 and nobody noticed for over a month. This adds a second,
# independent condition that reads the served cert's notAfter and fails
# early -- while the handshake still succeeds -- once expiry is under
# EXPIRY_WARN_DAYS out. The clean-404 assertion is unchanged; this augments
# it rather than replacing it.
set -uo pipefail

HOST="composer.omrihefez.com"
EXPIRY_WARN_DAYS="${EXPIRY_WARN_DAYS:-21}"

# bt-b130: days remaining between $1 (now, seconds since epoch) and $2 (an
# OpenSSL enddate string, e.g. "Oct 23 12:00:00 2026 GMT"). Pulled out as a
# pure function, independent of the network call that produces the enddate,
# so a fixture can prove the threshold arithmetic against a known date
# without waiting for a real cert to approach expiry -- the same reason the
# original bug went unnoticed for a month. Exits non-zero if $2 doesn't
# parse as a date.
days_remaining() {
  local now_epoch="$1" enddate="$2" end_epoch
  end_epoch=$(date -d "$enddate" +%s 2>/dev/null) || return 1
  echo $(( (end_epoch - now_epoch) / 86400 ))
}

# bt-b130: fetch $1's served certificate notAfter via a TLS handshake (same
# host/port a browser or curl would use) and report OK/EXPIRING/CHECK
# against threshold $2 days. Distinguishable from the FAIL emitted above on
# a hard connection error: this path only runs once the handshake already
# succeeded, so EXPIRING/CHECK here means "reachable now, but on notice" or
# "reachable but unreadable", never "already down".
check_cert_expiry() {
  local host="$1" threshold_days="$2" enddate days
  enddate=$(openssl s_client -connect "$host:443" -servername "$host" \
      </dev/null 2>/dev/null \
    | openssl x509 -noout -enddate 2>/dev/null | sed -n 's/^notAfter=//p')
  if [[ -z "$enddate" ]]; then
    echo "CHECK  $host: could not read certificate notAfter"
    return 1
  fi
  if ! days=$(days_remaining "$(date -u +%s)" "$enddate"); then
    echo "CHECK  $host: could not parse notAfter '$enddate'"
    return 1
  fi
  if (( days < threshold_days )); then
    echo "EXPIRING $host: cert expires in ${days}d (< ${threshold_days}d threshold, notAfter=$enddate)"
    return 1
  fi
  echo "OK     $host: cert has ${days}d remaining (notAfter=$enddate, threshold=${threshold_days}d)"
  return 0
}

main() {
  local exit_code=0 resp code

  if ! resp=$(curl -sI --max-time 10 "https://$HOST/" 2>&1); then
    echo "FAIL   $HOST TLS/connection error:"
    echo "$resp"
    exit 1
  fi

  code=$(echo "$resp" | head -1 | awk '{print $2}')
  if [[ "$code" == "404" ]]; then
    echo "OK     $HOST -> $code (clean fallback 404, cert valid)"
  else
    echo "CHECK  $HOST -> $code (expected 404)"
    echo "$resp"
    exit_code=1
  fi

  check_cert_expiry "$HOST" "$EXPIRY_WARN_DAYS" || exit_code=1

  exit "$exit_code"
}

# Sourced by test-monitoring.sh's fixture test to reach days_remaining()
# directly without running main() or touching the network; executed
# directly (including the sabotaged copy test-monitoring.sh's existing
# selftest sed's a bad HOST into) it behaves exactly as before.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
