---
id: bt-417b
title: tuner.omrihefez.com redirects to vercel.com/login instead of serving the site
  (bass.omrihefez.com works) — check Vercel Deployment Protection / domain config
status: done
priority: p2
tags:
  - deploy
created: 2026-07-21
done:
  at: 2026-07-22T08:14:04Z
  by: capacity-engine/worker
evidence:
  - type: live
    cmd: curl -s -o /dev/null -w '%{http_code}' https://tuner.omrihefez.com/ | grep -q '^200$'
    exit: 0
    at: 2026-07-22T08:14:04Z
    log: evidence/bt-417b-2026-07-22T08-14-04Z-live.txt
    sha256: 06a5982bd20428d8326942507817dceeb2b1640ce9f8cb6696b73abd06e5a0af
    bytes: 89
  - type: note
    value: "Root cause: tuner.omrihefez.com had correct DNS (CNAME to Vercel) but was never added as a
      domain on the bass-tuner Vercel project. Project Deployment Protection
      (ssoProtection.deploymentType=all_except_custom_domains) gated it as an unrecognized domain,
      redirecting to vercel.com/login. Fix: added tuner.omrihefez.com to the bass-tuner project's
      domains via Vercel API (auto-verified since DNS was already correct). No app code change;
      bass.omrihefez.com unaffected."
---

## Log
- 2026-07-22 claimed by capacity-engine
- 2026-07-22 released by capacity-engine
- 2026-07-22 claimed by capacity-engine
- 2026-07-22 released by capacity-engine
- 2026-07-22 claimed by capacity-engine
- 2026-07-22 released by capacity-engine
- 2026-07-22 claimed by capacity-engine
- 2026-07-22 done by capacity-engine/worker — live `curl -s -o /dev/null -w '%{http_code}' https://tuner.omrihefez.com/ | grep -q '^200$'` exit 0 (log: evidence/bt-417b-2026-07-22T08-14-04Z-live.txt)
