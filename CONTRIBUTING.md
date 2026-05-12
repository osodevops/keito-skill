# Contributing

## Development

This repository contains the `keito-time-track` Agent Skill plus its hook
installers and local test harness.

Keep the installed skill payload focused:

- `SKILL.md` contains the agent-facing workflow.
- `hooks/`, `scripts/`, and `installers/` contain executable behavior.
- `examples/` contains synthetic examples only.
- `README.md`, `SECURITY.md`, and this file are public repository docs.

## Local Verification

```bash
bash -n hooks/session-start.sh hooks/session-end.sh scripts/setup-wizard.sh \
  scripts/status.sh scripts/disable.sh scripts/install-cli.sh \
  installers/install-codex.sh installers/install-claude-code.sh tests/run.sh

shellcheck hooks/session-start.sh hooks/session-end.sh hooks/lib/*.sh \
  scripts/*.sh installers/*.sh tests/run.sh

tests/run.sh
```

The tests use fake `keito` commands and temporary state. They must not require a
real Keito account or create real time entries.

## Public Release Rules

- Do not commit `.keito/config.yml`.
- Do not commit real API keys, account IDs, client IDs, project IDs, or task IDs.
- Use `osodevops/keito-skill` in public install examples.
- Keep the installer package pinned to `skills@1.5.6` unless intentionally
  reviewed and updated.
- Pin GitHub Actions to full commit SHAs.
