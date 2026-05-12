# Keito Time Track Skill

[![CI](https://github.com/osodevops/keito-skill/actions/workflows/ci.yml/badge.svg)](https://github.com/osodevops/keito-skill/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Installer](https://img.shields.io/badge/skills-1.5.6-blue.svg)](https://www.npmjs.com/package/skills/v/1.5.6)
[![Keito CLI](https://img.shields.io/badge/requires-keito%20CLI-111827.svg)](https://github.com/osodevops/keito-cli)

Portable Agent Skill for recording Claude Code and Codex coding sessions as
Keito time entries.

## What It Does

- Installs Codex and Claude Code lifecycle hooks.
- Runs a repo setup wizard that maps one Git worktree to one Keito company,
  client, project, and task.
- Records one Keito `source=agent` time entry when a tracked coding session
  ends.
- Keeps credentials in the Keito CLI; this skill stores only repo-local IDs in
  `.keito/config.yml`.

## Install

```bash
brew install osodevops/tap/keito
keito auth login
keito skill install
```

The Keito CLI is the runtime engine. `keito skill install` installs this skill
from the GitHub skill repo, configures Claude Code and Codex hooks, and verifies
the local CLI/auth environment. The skill itself is not published to npm.

Audit-first install:

```bash
npx --yes skills@1.5.6 add osodevops/keito-skill -g -a codex -a claude-code -s keito-time-track -y --copy
keito skill install --skip-skills-add
```

If the CLI is not installed yet, the skill can guide the user through
`scripts/install-cli.sh`, then `keito auth login`, then `keito skill install`.

## Set Up A Repo

From a client repository:

```bash
/track-time-keito
```

The skill runs `scripts/setup-wizard.sh`, which uses the authenticated Keito CLI
to pick an existing client, project, and task, then asks for confirmation before
writing the repo-local `.keito/config.yml`.

Each repository needs its own `.keito/config.yml`. The hooks search upward only
within the current Git worktree, so one client or project config is not reused
from a neighbouring repository.

Do not commit `.keito/config.yml`; commit `examples/config.example.yml` only as
documentation for the expected shape.

To disable tracking for a repository:

```bash
scripts/disable.sh
```

## Runtime

- `hooks/session-start.sh` records local state when a tracked repo session
  starts.
- `hooks/session-end.sh` computes wall-clock duration and calls:

```bash
keito --json time session-record \
  --project <project_id> \
  --task <task_id> \
  --session-id <session_id> \
  --duration-seconds <seconds> \
  --source agent
```

The hook is best-effort: failures are written to `~/.keito/skill/skill.log` and
never fail the agent session.

## Security

- API keys stay in the Keito CLI config or environment.
- `.keito/config.yml` stores company/client/project/task IDs, not credentials.
- Session notes can be redacted with `agent_tracking.redact_notes: true`.
- Entries are tagged with `metadata.integration=keito_skill` and `source=agent`.
- `npx` is only used to run the pinned `skills@1.5.6` installer package.
- GitHub Actions in this repo are pinned to commit SHAs and run with read-only
  repository permissions.
- CI rejects floating `skills` installer references and unpinned GitHub Actions.

See [SECURITY.md](SECURITY.md) for reporting and supply-chain expectations.

## Local Verification

```bash
tests/run.sh
```

The test harness uses a fake `keito` executable and temporary session state, so
it does not touch real Keito credentials or create real time entries.

For contribution workflow and full local checks, see
[CONTRIBUTING.md](CONTRIBUTING.md).
