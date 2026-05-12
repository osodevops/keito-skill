# Keito Time Track Skill

Portable Agent Skill for recording Claude Code and Codex coding sessions as
Keito time entries.

## Install

```bash
brew install osodevops/tap/keito
keito auth login
keito skill install
```

The Keito CLI is the runtime engine. `keito skill install` installs this skill
with `npx skills`, configures Claude Code and Codex hooks, and verifies the
local CLI/auth environment.

Audit-first install:

```bash
npx skills add keito-ai/keito-skill -g -a codex -a claude-code -s keito-time-track -y --copy
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

## Local Verification

```bash
tests/run.sh
```

The test harness uses a fake `keito` executable and temporary session state, so
it does not touch real Keito credentials or create real time entries.
