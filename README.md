# Keito Time Track Skill

Portable Agent Skill for recording Claude Code and Codex coding sessions as
Keito time entries.

## Install Locally

```bash
installers/install-claude-code.sh
installers/install-codex.sh
```

The installers copy this package into the agent skill directory and merge
session hooks into the local hook config.

## Set Up A Repo

From a client repository:

```bash
/track-time-keito
```

The skill runs `scripts/setup-wizard.sh`, which uses the Keito CLI to pick an
existing project and task, then writes `.keito/config.yml`.

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

## Local Verification

```bash
tests/run.sh
```

The test harness uses a fake `keito` executable and temporary session state, so
it does not touch real Keito credentials or create real time entries.
