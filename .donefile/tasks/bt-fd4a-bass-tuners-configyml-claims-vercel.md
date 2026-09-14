---
id: bt-fd4a
title: bass-tuner's config.yml claims Vercel git-integrated auto-deploy, but the project has no git link
status: done
priority: p2
tags:
  - docs
created: 2026-09-14
filed:
  owner: meni-worker/apartment-planner-s-ci-w-6de027
  at: 2026-09-14T06:40:57Z
done:
  at: 2026-09-14T07:13:04Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: 93ce83b61658aac3eddebf6663365a482c47110e
    verified: 2026-09-14T07:13:04Z
  - type: test
    cmd: "cd /home/omri/projects/bass-tuner && TOKEN=$(node -e
      \"console.log(require('/home/omri/.local/share/com.vercel.cli/auth.json').token)\") &&
      LOCAL_SHA=$(git rev-parse origin/main) && REMOTE_SHA=$(curl -sf
      \"https://api.vercel.com/v6/deployments?projectId=prj_Se9EWsbcw9VUJKDVNuWh7tw65nPR&teamId=tea\
      m_1JqV1IChqxsh933CUDYmVvGQ&target=production&limit=1\" -H \"Authorization: Bearer $TOKEN\" |
      node -e \"let
      d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{console.log(JSON.parse(d).d\
      eployments[0].meta.githubCommitSha)})\") && [ \"$LOCAL_SHA\" = \"$REMOTE_SHA\" ]"
    exit: 0
    at: 2026-09-14T07:13:03Z
    log: evidence/bt-fd4a-2026-09-14T07-13-03Z-test.txt
    sha256: 2462445f3a27e68ceacd120c2d47913c19ed5ac43ca4fde85f5f8e4096b39aeb
    bytes: 569
  - type: note
    value: "not real / already fixed: vercel project inspect (CLI) shows no Git section, but the raw
      Vercel API confirms link.type==github, repo omrihefez/tuner. Empirically: origin/main's last
      several pushes (incl. today's c353e33, 93ce83b) each produced a matching source=git
      target=production READY deployment within seconds. config.yml's git-auto-deploy claim is
      accurate as written; no change needed. Task filer pattern-matched apl-7e50 (apartment-planner)
      where the API genuinely had no link field -- bass-tuner's API does have one."
---

Found while working apl-7e50 (apartment-planner), which had the identical false claim. .donefile/config.yml lines 58-59 say: 'git-integrated (unlike meni-arch...) so a push to origin/main auto-deploys to production'. Checked with 'vercel project inspect bass-tuner': the output has NO Git section (a git-linked Vercel project shows one) — confirms no git integration, same signature as apartment-planner (Vercel project API had no link field there). So pushing origin/main here likely deploys nothing either, same risk: a worker who pushes and sees a green push may believe it shipped when it did not. DONE WHEN: config.yml states the real deploy mechanism (verify whether it's vercel deploy --prod by hand, or something else — check for a deploy script/CI workflow first), and confirm empirically the same way apl-7e50 did: push a no-op, confirm no new deployment, confirm the real command produces one.

## Log
- 2026-09-14 claimed by capacity-engine
- 2026-09-14 done by capacity-engine/worker — commit 93ce83b61658, test `cd /home/omri/projects/bass-tuner && TOKEN=$(node -e "console.log(require('/home/omri/.local/share/com.vercel.cli/auth.json').token)") && LOCAL_SHA=$(git rev-parse origin/main) && REMOTE_SHA=$(curl -sf "https://api.vercel.com/v6/deployments?projectId=prj_Se9EWsbcw9VUJKDVNuWh7tw65nPR&teamId=team_1JqV1IChqxsh933CUDYmVvGQ&target=production&limit=1" -H "Authorization: Bearer $TOKEN" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{console.log(JSON.parse(d).deployments[0].meta.githubCommitSha)})") && [ "$LOCAL_SHA" = "$REMOTE_SHA" ]` exit 0 (log: evidence/bt-fd4a-2026-09-14T07-13-03Z-test.txt)
