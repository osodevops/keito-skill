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
claude plugin marketplace add osodevops/keito-skill
```

## Supply Chain Rules

- The skill is installed from GitHub, not published as an npm package.
- `npx` is only used to run the exact `skills@1.5.6` installer package.
- GitHub Actions must be pinned to full commit SHAs.
- Workflows should run with least-privilege `permissions`.
- Do not commit `.keito/config.yml`, API keys, or live customer/project IDs.
- Keep examples in `keito-time-track/assets/` synthetic and non-sensitive.
- Keep Claude Code plugin metadata under `.claude-plugin/` validated before
  release.

## Local Checks

Run these before opening or updating a PR:

```bash
bash -n keito-time-track/hooks/session-start.sh keito-time-track/hooks/session-end.sh \
  keito-time-track/scripts/setup-wizard.sh keito-time-track/scripts/status.sh \
  keito-time-track/scripts/disable.sh keito-time-track/scripts/install-cli.sh \
  keito-time-track/installers/install-codex.sh \
  keito-time-track/installers/install-claude-code.sh tests/run.sh

npx --yes skills-ref@0.1.5 validate keito-time-track
npx --yes skills@1.5.6 add . -l
jq empty .claude-plugin/plugin.json .claude-plugin/marketplace.json hooks/hooks.json
claude plugin validate .
claude plugin validate .claude-plugin/plugin.json

shellcheck -P keito-time-track keito-time-track/hooks/session-start.sh \
  keito-time-track/hooks/session-end.sh keito-time-track/hooks/lib/*.sh \
  keito-time-track/scripts/*.sh keito-time-track/installers/*.sh tests/run.sh

tests/run.sh
```
