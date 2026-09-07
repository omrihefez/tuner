#!/usr/bin/env bash
# ff-sync-main-checkout.sh — fast-forwards bass-tuner's shared main checkout
# (/home/omri/projects/bass-tuner) onto whatever origin/main actually is.
# Thin wrapper around the shared implementation in donefile's
# scripts/lib/ff-sync-checkout-lib.sh (ce-4f1c) — that file has the full
# why/how (previously duplicated here as bt-31a9); this file only supplies
# bass-tuner's own config: the 5 monitoring crons (fallback-cert/domain-
# audit/heartbeat/stale-deploy/cert-renewal) run straight out of this
# checkout's working tree with no build step, so whatever is on disk here is
# what actually runs.
set -uo pipefail

FF_SYNC_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FF_SYNC_BRANCH="main"
FF_SYNC_LABEL="ff-sync-bass-tuner-main-checkout"
FF_SYNC_CONSUMER_DESC="the monitoring crons (fallback-cert/domain-audit/heartbeat/stale-deploy/cert-renewal)"
FF_SYNC_LIB="${FF_SYNC_LIB:-/home/omri/projects/donefile/scripts/lib/ff-sync-checkout-lib.sh}"
source "$FF_SYNC_LIB"
ff_sync_run
exit $?
