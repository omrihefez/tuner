# Activation probes

Live probes for this board's **activation-gated** tasks (`pwa` / `ux` /
`correctness` / `security` / `deploy` / `feature` / `perf` / `a11y` /
`vercel` tags — see `.donefile/config.yml`): scripts that prove a merged fix
is actually *live on bass.omrihefez.com*, not merely committed. Written for
bt-a60b, which found this board had no activation gate at all — `donefile
done` closed on a bare commit for a deployed Vercel PWA, with no `--live`
probe ever required.

Each script is the `--live` evidence for one task, so `donefile done <id>
--live "bash /home/omri/projects/bass-tuner/deploy/activation-probes/probe-<id>.sh"`
re-runs the real proof rather than replaying an assertion someone once made.

## The bar

A probe here must hit the **real served site** (bass.omrihefez.com over
HTTPS, exactly as a browser would fetch it) — never a re-read of the diff,
the local repo file, or `vercel.json` on disk. If writing the `--live`
command would just re-derive information the `--commit` or `--test` evidence
already established, there's no runtime surface to probe — see the waiver
rule below instead.

Every probe should be shown able to FAIL — run it against a stale git ref
(a commit before the fix) as a negative control and confirm it reports
failure, not just success against HEAD.

| probe | negative control |
|---|---|
| `probe-bt-5fb7.sh` | run against `e53825c` (an old `tuner-v6` commit, long superseded) instead of HEAD — the live CACHE (`tuner-v10`) must NOT match, and the script must report FAIL |

## No runtime surface: waive, don't fake a probe

Activation gating is applied by **tag**, not by whether the task actually
produced a deployed or running artifact. A tooling/process/config task can
carry a gated tag (e.g. `deploy`) descriptively without ever touching served
content — bt-a60b itself (this gate's own config.yml + README) is exactly
that case. For those, don't paper over the gap with a probe that only
re-reads the diff or re-runs the `--test` command as `--live` — use
`donefile done <id> --waive "<reason>"`, same escape hatch meniapp's
ma-dffe documents and this board already uses for genuinely evidence-free
work.

## Results

| task | verdict |
|---|---|
| bt-5fb7 | LIVE — deployed sw.js CACHE (`tuner-v10`) matches HEAD's source; negative control against `e53825c` correctly fails |
