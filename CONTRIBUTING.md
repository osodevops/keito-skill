# Contributing

Keep lifecycle scripts thin. Accounting, consent, identity, durable storage and
transport belong to the CLI core, not shell scripts. Do not add transcript reads,
model-written notes, implicit repository approval or financial calculations.

Run the dependency-free adapter/installer suite with `tests/run.sh`. It is also
bundled under `keito-time-track/tests/adapter_installer_test.py` so the CLI can
verify exactly the shipped skill. Both copies must match byte-for-byte.

```bash
tests/run.sh
find keito-time-track tests -name '*.sh' -print0 | xargs -0 -n1 bash -n
find keito-time-track tests -name '*.sh' -print0 | xargs -0 shellcheck -P keito-time-track
npx --yes skills-ref@0.1.5 validate keito-time-track
jq empty .claude-plugin/plugin.json .claude-plugin/marketplace.json hooks/hooks.json
```

The suite uses temporary HOME and a fake CLI, including injected configuration
replacement failure, real SIGTERM/SIGKILL at publication boundaries, setup
failure/recovery, strict command ownership and parent-symlink refusal. The
one-second installed-host timeout test uses a core that ignores TERM; its
assertion is not relaxed to a longer synthetic allowance. Never test installers against a developer's real settings.
Real harness trust, exact versions, latency, accepted server records and unsent
invoice evidence require separate qualification. Do not claim the local suite
proves those release gates.

Pin GitHub Actions to full commit SHAs. If using the optional open skills
installer, keep its package pinned to `skills@1.5.6`. The default distribution is
the CLI bundle. Keep examples synthetic, credentials out of the repository and
publisher branding as OSO.
