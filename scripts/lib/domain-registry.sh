#!/usr/bin/env bash
# domain-registry.sh — derives the omrihefez.com estate's live/alias
# subdomain list from ~/meni/DOMAIN.md §1 at runtime (ma-20c5), so a
# monitor's host list cannot silently drift from the registry the way two
# hand-copied arrays already had: meniapp/scripts/check-cert-expiry.sh's
# DEFAULT_HOSTS was still watching `albumclub` a week after its Vercel
# project, Cloudflare CNAME and Neon DB were all deleted, and this repo's
# audit-domains.sh's SUBS was missing `meniapp`, `meniapp-api` and
# `tik-api` — the three most production-critical names in the zone.
# DOMAIN.md lives in omrihefez/meni, which workers on this box may not
# commit to, so the fix reads it at runtime instead of duplicating it.
#
# This file is duplicated into meniapp and bass-tuner (separate git repos, no
# shared package). What must stay in sync is derive_registry_hosts's
# BEHAVIOUR — same registry in, same host list out — not the file's bytes:
# this header is allowed to differ per repo (each side names the OTHER
# repo's audit-domains.sh from its own point of view, by design). ma-6493's
# meniapp/scripts/check-domain-registry-sync.sh (cron 13 6 * * *) verifies
# the behavioural claim daily by sourcing both copies against a shared
# fixture and diffing their output — it is NOT a whole-file identity check,
# which would go red on this header alone. There is deliberately no
# .vendored.sh pinned-copy sibling for this file: that convention is for a
# private copy shadowing one canonical implementation, which isn't this
# shape (there is no single canonical copy — DOMAIN.md lives in a repo
# neither side may commit to); the sync check above is the guard instead.
#
# Only §1 rows whose Status column is 🟢 live or 🔵 alias qualify. Apex
# (`omrihefez.com`, whose name cell is already a fully-qualified domain, not
# a bare label) is excluded by an anchored `omrihefez\.com$` match on the
# name, on top of its own 🟠 status already failing the emoji filter.
# Tombstoned (🔴), needs-attention (🟠), pending-removal (🕯️), held (⛔) and
# email-infra (✉️) rows are excluded the same way.
#
# That exclusion is ANCHORED, not a bare "contains a dot" test, since bt-7f07
# (2026-10-10). The dot test also dropped every legitimate MULTI-LABEL host in
# the zone — `preview.meni`, meni-arch's live passkey-gated staging alias —
# and dropped it SILENTLY, so adding a registry row for such a host could not
# restore cert-expiry or domain-audit coverage and nothing said why. The
# anchored form keeps the apex guard load-bearing: §6 contemplates the apex
# going 🟢 live, at which point the status filter stops excluding it and a
# bare `omrihefez.com` would reach callers that append `.omrihefez.com`
# themselves, yielding `omrihefez.com.omrihefez.com`. Measured both ways
# against a fixture before and after. Do NOT "simplify" this back to a dot
# test, and do not delete it on the grounds that the status filter already
# covers today's apex row — it covers only today's STATUS.

# derive_registry_hosts <domain_md_path> [vercel|non-vercel]
#   Prints one bare subdomain label per line (no .omrihefez.com suffix —
#   callers append their own). Mode filters on the Host column: "vercel"
#   keeps only rows whose Host cell contains "Vercel"; "non-vercel" keeps
#   the rest; omitted/"all" keeps every live/alias row regardless of host.
#   Returns non-zero with no output if the file can't be read.
derive_registry_hosts() {
  local file="$1" mode="${2:-all}"
  [ -r "$file" ] || return 1
  awk -F'|' -v mode="$mode" '
    NF < 8 { next }
    {
      name = $2; host = $5; status = $7
      is_live = (status ~ /🟢/ || status ~ /🔵/)
      if (!is_live) next
      if (name !~ /`/ || !match(name, /`[^`]*`/)) {
        print "derive_registry_hosts: skipping unrepresentable live/alias row (no backtick-quoted name): " name > "/dev/stderr"
        next
      }
      raw = substr(name, RSTART + 1, RLENGTH - 2)
      if (raw ~ /omrihefez\.com$/) {
        print "derive_registry_hosts: skipping apex-shaped live/alias row (excluded by design): " raw > "/dev/stderr"
        next
      }
      is_vercel = (host ~ /Vercel/)
      if (mode == "vercel" && !is_vercel) next
      if (mode == "non-vercel" && is_vercel) next
      print raw
    }
  ' "$file"
}
