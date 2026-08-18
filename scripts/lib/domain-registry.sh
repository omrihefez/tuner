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
# This file is duplicated verbatim in meniapp and bass-tuner (separate git
# repos, no shared package) — keep the two copies identical.
#
# Only §1 rows whose Status column is 🟢 live or 🔵 alias qualify. Apex
# (`omrihefez.com`, whose name cell is already a fully-qualified domain, not
# a bare label) is excluded by construction via the "contains a dot" check,
# on top of its own 🟠 status already failing the emoji filter. Tombstoned
# (🔴), needs-attention (🟠), pending-removal (🕯️), held (⛔) and
# email-infra (✉️) rows are excluded the same way.

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
      if (name !~ /`/) next
      if (!match(name, /`[^`]*`/)) next
      raw = substr(name, RSTART + 1, RLENGTH - 2)
      if (raw ~ /\./) next
      if (status !~ /🟢/ && status !~ /🔵/) next
      is_vercel = (host ~ /Vercel/)
      if (mode == "vercel" && !is_vercel) next
      if (mode == "non-vercel" && is_vercel) next
      print raw
    }
  ' "$file"
}
