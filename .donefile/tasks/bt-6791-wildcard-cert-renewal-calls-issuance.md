---
id: bt-6791
title: Wildcard cert renewal calls issuance a success by grepping output for 'success', which also
  matches 'unsuccessful' — a false success exits 0 so nothing alerts
status: claimed
priority: p2
tags:
  - reliability
  - certs
  - security
created: 2026-10-08
filed:
  owner: meni-worker/board-refill-work-discov-9e7c91
  at: 2026-10-08T13:35:11Z
claim:
  owner: capacity-engine
  at: 2026-10-08T14:14:38Z
---

`scripts/renew-wildcard-cert.sh` decides the wildcard certificate was issued by
grepping the CLI's output for the string "success", and the pattern it uses also
matches "unsuccessful". A false success here exits 0, so nothing alerts, the
challenge record is deleted, and the log asserts the renewal worked.

THE LINE, scripts/renew-wildcard-cert.sh:212-222:

    issue_out=$(vercel certs issue "$CN" --non-interactive 2>&1)
    issue_exit=$?
    echo "$issue_out"
    issue_ok=0
    if [[ "$issue_exit" -eq 0 ]] && echo "$issue_out" | grep -qi "success"; then
      issue_ok=1
    fi
    if [[ "$issue_ok" -ne 1 ]]; then
      log "FATAL: issuance did not report success, leaving TXT record in place for inspection"
      exit 1
    fi
    log "issuance succeeded"

`grep -qi "success"` is a SUBSTRING match with no word boundary, so every one of
these sets `issue_ok=1`:

    "Certificate issuance was unsuccessful"
    "unsuccessfully issued"
    "Error: renewal unsuccessful for *.omrihefez.com"

The `issue_exit -eq 0` conjunct is what makes this a latent defect rather than a
live one — both halves must agree. But the two halves exist precisely because
the author did not trust the exit code alone, and a pattern that matches the
NEGATION of the word it is looking for makes the second half worse than absent:
it converts an explicit failure message into a positive verdict. That is the
"a command succeeded if it EXITED 0 — never because its output matched a
pattern" trap, in its most literal form.

WHY THE CONSEQUENCE IS DISPROPORTIONATE TO THE TYPO:

- The cert is `*.omrihefez.com`. Per `~/meni/DOMAIN.md` §1 the wildcard is what
  serves every host that has no explicit record, and the registry's own note
  says the wildcard "makes DNS lie" — so this one cert sits under most of the
  estate's public surfaces.
- FAILURE IS LOUD, SUCCESS IS SILENT, and this bug converts the first into the
  second. The cron is `17 6 * * 1 .../run-monitor.sh cert-renewal ...`
  (crontab, weekly Monday 06:17). `run-monitor.sh` alerts via meni-notify on
  ANY non-zero exit, with a fingerprint latch (run-monitor.sh:56-76). Exit 0
  means no alert at all. So a false success is the one outcome nobody hears
  about.
- It also destroys its own evidence: line 226 deletes the challenge TXT record
  on the success path, while line 220's real failure path deliberately leaves it
  "in place for inspection". A false success takes the cleanup branch.
- The only backstop is a human. bt-b130 recorded it in those words: the fallback
  is "a calendar reminder pointed at the next expiry (2026-10-23) — a human
  remembering". ma-e61d then found that reminder's date STALE against a cert
  actually valid to 2026-12-20. So the one compensating control is a reminder
  whose date has already drifted once.
- Weekly cadence means one swallowed failure costs seven days before the next
  attempt.

A SECOND, SMALLER ONE IN THE SAME SCRIPT, worth fixing in the same pass
(line 152):

    days_left=$(vercel certs ls --non-interactive 2>/dev/null | awk ... )
    if [[ -z "$days_left" ]]; then
      log "WARN: could not parse days-until-expiry for $CN from 'vercel certs ls'; proceeding to renew to be safe"

`2>/dev/null` on the one authenticated read discards the reason it failed. The
dominant real cause is a dead Vercel credential: df-0733 documents that
`vercel login` writes an access token ~8 hours out, that the CLI only refreshes
it when something invokes `vercel`, and that once dead only an interactive
device code revives it. This weekly cron is the LOWEST-frequency Vercel consumer
on the box, so it is the most likely to meet a cold credential — and when it
does, the message naming that cause is thrown away and the log says
"could not parse days-until-expiry" instead. The script then proceeds and dies
at line 171-173 with "FATAL: could not parse challenge TXT value", a third
wrong cause. Partially mitigated: line 168 keeps `2>&1` and line 169 echoes it,
so the real auth error does reach the log — just after two misleading lines and
under a FATAL that names something else.

DONE WHEN:
- The success verdict no longer rests on a substring of free-form CLI output.
  Anchor it (`grep -qiE '(^|[^[:alpha:]])success(ful(ly)?)?([^[:alpha:]]|$)'`
  at minimum), or better, verify the ARTIFACT: re-read the cert's expiry
  afterwards and assert it moved. The repo already has
  `scripts/check-cert-expiry.sh` for reading expiry — asserting the new
  not-after is later than the old one is a check that cannot be satisfied by
  wording.
- SEEN TO FAIL FIRST. Feed the function the literal string
  "Error: renewal unsuccessful for *.omrihefez.com" with exit 0 and confirm the
  CURRENT code sets issue_ok=1, then confirm the fix sets it to 0. That negative
  control is the evidence; a passing run of the real cron proves nothing here,
  because the real cron has always passed.
- Keep stderr on the `certs ls` read and surface an auth failure AS an auth
  failure, so a cold Vercel credential names itself instead of arriving as an
  unparseable expiry. If it is an auth failure, exit non-zero so run-monitor
  alerts, rather than proceeding into a renewal that cannot work.
- Do NOT run `--force --i-mean-it` against the live cert to test this. The cert
  is healthy to 2026-12-20 (ma-e61d) and a real issuance mutates DNS in the live
  zone. Drive the verdict logic directly with fixture strings.

## Log
- 2026-10-08 claimed by capacity-engine
