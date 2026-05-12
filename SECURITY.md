# Security Policy

## Reporting

Please report suspected vulnerabilities privately to the Keito maintainers before
opening a public issue. Include the affected commit, reproduction steps, and any
logs that do not contain secrets.

## Supported Branch

Security fixes target the active distribution branch for `keito-time-track`.
The public install path should use:

```bash
npx --yes skills@1.5.6 add osodevops/keito-skill -g -a codex -a claude-code -s keito-time-track -y --copy
```

## Supply Chain Rules

- The skill is installed from GitHub, not published as an npm package.
- `npx` is only used to run the exact `skills@1.5.6` installer package.
- GitHub Actions must be pinned to full commit SHAs.
- Workflows should run with least-privilege `permissions`.
- Do not commit `.keito/config.yml`, API keys, or live customer/project IDs.
- Keep examples in `examples/` synthetic and non-sensitive.

## Local Checks

Run these before opening or updating a PR:

```bash
bash -n hooks/session-start.sh hooks/session-end.sh scripts/setup-wizard.sh \
  scripts/status.sh scripts/disable.sh scripts/install-cli.sh \
  installers/install-codex.sh installers/install-claude-code.sh tests/run.sh

shellcheck hooks/session-start.sh hooks/session-end.sh hooks/lib/*.sh \
  scripts/*.sh installers/*.sh tests/run.sh

tests/run.sh
```
