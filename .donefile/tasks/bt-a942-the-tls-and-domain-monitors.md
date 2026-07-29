---
id: bt-a942
title: The TLS and domain monitors are unobserved - check-fallback-cert.sh and audit-domains.sh are
  scheduled nowhere, and the renewal cron writes only to an unread log
status: open
priority: p2
tags:
  - tls
  - ops
created: 2026-07-29
---

grep across bass-tuner and ~/meni/bin and ~/meni/scripts finds check-fallback-cert.sh and audit-domains.sh referenced ONLY inside their own .donefile task files as one-shot closing evidence for bt-2b10 and bt-a740. No cron, no CI workflow, no morning-brief hook runs either one. They have each executed exactly once, on the day they were written. renew-wildcard-cert.sh IS crontabbed by install-cert-renewal-cron.sh line 23, Monday 06:17, but its whole output goes to ~/.cache/bass-tuner-cert-renewal.log and nothing reads that file - so every FATAL path in the script, expired Cloudflare token, a vercel certs ls format change, TXT propagation timeout, unauthenticated Vercel CLI, fails invisibly. That is the exact failure mode these three scripts exist to prevent: the wildcard fallback cert expired silently on 2026-06-17 and went unnoticed for over a month. Compare iac/scripts/drift-check.sh, which writes ~/inbox/iac-drift-DATE.md on any error precisely because, in its own words, a silent monitor is a broken monitor. DONE WHEN: all three scripts run on a schedule and any non-zero exit writes a dated file into ~/inbox so the morning brief surfaces it. Verify by forcing each script to fail and confirming a matching ~/inbox file appears.
