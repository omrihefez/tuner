---
id: bt-0ead
title: Migrate bass-tuner's 5 argv-secret offenders to env-var/stdin-fed form (ma-529d)
status: done
priority: p3
tags:
  - security
  - fleet
created: 2026-10-05
filed:
  owner: meni-worker/migrate-the-177-baseline-c8a687
  at: 2026-10-05T01:35:45Z
done:
  at: 2026-10-05T05:37:32Z
  by: capacity-engine/worker
  waived: "security tag false-positive for activation-gating: the two touched files
    (scripts/check-model-ids-resolve.sh, scripts/renew-wildcard-cert.sh) are standalone cron-invoked
    monitor/renewal scripts, not part of the Vercel-served PWA app surface
    (HTML/CSS/JS/manifest/sw.js/vercel.json) this board's activation gate exists for. Nothing
    deployed, no service restarted -- the fix takes effect automatically the next time cron invokes
    either script. Confirmed neither file is referenced from index.html/sw.js/manifest.json or
    vercel.json."
evidence:
  - type: commit
    value: 14bf41bb907fb9cf5d739a4420aa811b3c2f12cb
    verified: 2026-10-05T05:37:32Z
  - type: test
    cmd: "git -C /home/omri/projects/bass-tuner fetch -q origin main && git -C
      /home/omri/projects/bass-tuner merge-base --is-ancestor
      14bf41bb907fb9cf5d739a4420aa811b3c2f12cb origin/main && git -C /home/omri/projects/bass-tuner
      show origin/main:scripts/renew-wildcard-cert.sh | grep -F 'printf '\\''header =
      \"Authorization: Bearer %s\"' >/dev/null"
    exit: 0
    at: 2026-10-05T05:37:31Z
    log: evidence/bt-0ead-2026-10-05T05-37-31Z-test.txt
    sha256: 4cd1641774bc5e01cf83c9d368115a2ec0ec2645b5e505df1577de1689929706
    bytes: 340
  - type: note
    value: "5 argv-secret offenders fixed: check-model-ids-resolve.sh:275,289 and
      renew-wildcard-cert.sh:125,139,143 switched from curl -H with a live secret interpolation to
      curl --config on a process-substitution fd (meniapp ma-529d shape: printf 'header = \"...:
      Bearer %s\"' | --config <(...)). Verified before/after with a /proc/<pid>/cmdline check
      (secret literally visible on argv before the fix, absent after -- only --config /dev/fd/N
      shows), the existing hermetic suite (check-model-ids-resolve.test.sh, 9 assertions) still
      green post-fix, and meniapp's own scan-argv-secret-exposure.py reporting 0 offenders for this
      repo (was 5, all matching deploy/argv-secret-exposure-baseline.tsv rows 91-95). Landed ff on
      main (cc3b6f9..14bf41b) via a promote/* branch rename per the pre-push guard. These 5 baseline
      rows can now be dropped from meniapp's deploy/argv-secret-exposure-baseline.tsv -- not done
      here, path-scoped, meniapp owns that file."
---

Named in the finding: env-var/stdin-fed (ma-529d, meniapp).

5 argv-secret offenders (credential-shaped CLI flag/HTTP header fed a live
$VAR/${VAR}/$(...) interpolation instead of an env var or stdin-fed config)
tracked in meniapp's deploy/argv-secret-exposure-baseline.tsv, all under this
repo:

  scripts/check-model-ids-resolve.sh
  scripts/renew-wildcard-cert.sh

(run meniapp's scripts/scan-argv-secret-exposure.py --root <this repo> to get
exact line numbers — the baseline tsv hashes full matched lines, not numbers).

Safe shapes (meniapp's scripts/check-argv-secret-exposure.sh header has the
canonical writeup): drop --client-id=/--client-secret=, let infisical read
INFISICAL_UNIVERSAL_AUTH_CLIENT_ID/SECRET from env; feed a curl Authorization
header via `--config` on a stdin pipe (`printf 'header = "Authorization:
Bearer %s"\n' "$TOK" | curl --config - ...`) or, if the same header is reused
across several curl calls from one array/variable, a 600-mode tmp file
instead (a process-substitution fd can only be read once).

meniapp fixed its own 79-entry share of this same finding in ea6a0fa7..36ccbe88
(ma-529d) — same pattern, copy the shape, verify with a before/after
/proc/<pid>/cmdline check (curl's own argv should show --config /dev/fd/N or
--config <path>, never the secret) plus `bash -n` on every touched file.

DONE WHEN: these 5 call sites no longer put a live credential on argv, and
meniapp's deploy/argv-secret-exposure-baseline.tsv no longer needs these rows
(note here when done so meniapp can drop them, or drop them yourself if you
have write access there — path-scoped, do not touch other repos' rows).

## Log
- 2026-10-05 claimed by capacity-engine
- 2026-10-05 released by capacity-engine
- 2026-10-05 claimed by capacity-engine
- 2026-10-05 done by capacity-engine/worker — commit 14bf41bb907f, test `git -C /home/omri/projects/bass-tuner fetch -q origin main && git -C /home/omri/projects/bass-tuner merge-base --is-ancestor 14bf41bb907fb9cf5d739a4420aa811b3c2f12cb origin/main && git -C /home/omri/projects/bass-tuner show origin/main:scripts/renew-wildcard-cert.sh | grep -F 'printf '\''header = "Authorization: Bearer %s"' >/dev/null` exit 0 (log: evidence/bt-0ead-2026-10-05T05-37-31Z-test.txt) (evidence waived: security tag false-positive for activation-gating: the two touched files (scripts/check-model-ids-resolve.sh, scripts/renew-wildcard-cert.sh) are standalone cron-invoked monitor/renewal scripts, not part of the Vercel-served PWA app surface (HTML/CSS/JS/manifest/sw.js/vercel.json) this board's activation gate exists for. Nothing deployed, no service restarted -- the fix takes effect automatically the next time cron invokes either script. Confirmed neither file is referenced from index.html/sw.js/manifest.json or vercel.json.)
