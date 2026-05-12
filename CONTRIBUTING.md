# Contributing

## Development

This repository contains the `keito-time-track` Agent Skill plus its hook
installers and local test harness.

Keep the installed skill payload focused:

- `keito-time-track/SKILL.md` contains the agent-facing workflow.
- `keito-time-track/hooks/`, `keito-time-track/scripts/`, and
  `keito-time-track/installers/` contain executable behavior.
- `keito-time-track/assets/` contains synthetic examples and templates only.
- `README.md`, `SECURITY.md`, and this file are public repository docs.

## Local Verification

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

The tests use fake `keito` commands and temporary state. They must not require a
real Keito account or create real time entries.

## Public Release Rules

- Do not commit `.keito/config.yml`.
- Do not commit real API keys, account IDs, client IDs, project IDs, or task IDs.
- Use `osodevops/keito-skill` in public install examples.
- Use `OSO` for publisher/owner-facing brand text.
- Keep the installer package pinned to `skills@1.5.6` unless intentionally
  reviewed and updated.
- Pin GitHub Actions to full commit SHAs.
