---
id: bt-fd4a
title: bass-tuner's config.yml claims Vercel git-integrated auto-deploy, but the project has no git link
status: open
priority: p2
tags:
  - docs
created: 2026-09-14
filed:
  owner: meni-worker/apartment-planner-s-ci-w-6de027
  at: 2026-09-14T06:40:57Z
---

Found while working apl-7e50 (apartment-planner), which had the identical false claim. .donefile/config.yml lines 58-59 say: 'git-integrated (unlike meni-arch...) so a push to origin/main auto-deploys to production'. Checked with 'vercel project inspect bass-tuner': the output has NO Git section (a git-linked Vercel project shows one) — confirms no git integration, same signature as apartment-planner (Vercel project API had no link field there). So pushing origin/main here likely deploys nothing either, same risk: a worker who pushes and sees a green push may believe it shipped when it did not. DONE WHEN: config.yml states the real deploy mechanism (verify whether it's vercel deploy --prod by hand, or something else — check for a deploy script/CI workflow first), and confirm empirically the same way apl-7e50 did: push a no-op, confirm no new deployment, confirm the real command produces one.
