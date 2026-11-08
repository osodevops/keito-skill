# Keito coding-agent capture adapters

These adapters connect selected Claude Code and Codex lifecycle events to the
Keito CLI's metadata-only capture core. The CLI owns exact interval accounting,
repository consent, the durable queue and canonical session delivery. Authorized
review controls whether activity becomes a client charge.

This branch is a capture-contract candidate. Installed files and passing local
adapter tests do not establish real harness dispatch, trusted hooks, successful
API delivery or demo readiness. Qualify exact CLI, adapter and harness artifacts
before use; the implementation does not claim usage capture or actual provider
costs without separate evidence.

## Install selected adapters

Use a CLI release that exposes `keito capture --help`. CLI installation defaults
to its bundled skill, so its tested payload and runtime travel together:

```bash
brew install osodevops/tap/keito
keito auth login
keito skill install --agent claude-code --agent codex
```

Select only `--agent codex` or `--agent claude-code` for a single harness. The
portable installer also requires explicit targets:

```bash
keito-time-track/installers/install.sh --agent claude-code --agent codex
```

Installers require Bash, Python 3 and a compatible Keito CLI; the optional setup
picker uses jq. The installer records the selected installed harness version
when available. `--harness-version` may pin the exact version during a qualified
rehearsal. A recorded version is provenance, not a compatibility certification.

Existing unrelated hooks and plugin settings are preserved. Legacy Keito
financial hooks or a simultaneous Keito Claude plugin require an explicit
`--confirm-migration` after review. A legacy payload is retained in a hidden
backup beside the skill. Do not install both plugin and direct hooks to the same
harness. The shared core still must deduplicate repeated lifecycle delivery.

Codex `features.hooks`, managed configuration and hook-trust records are never
changed by these installers. Review/enable hooks through normal Codex settings
and trust prompts. Do not bypass trust. Updating executable hooks may require
renewed review. `capture-install.json` records trust as unknown and delivery as
unverified until a real qualification establishes them.

## Approve a repository mapping

From the intended repository, select existing records and approve the mapping:

```bash
keito-time-track/scripts/setup-wizard.sh --agent claude-code --agent codex --install-worker
```

For scripted setup, use the CLI directly with explicit project/task IDs and
confirmation after inspecting the capture policy:

```bash
keito --workspace <workspace-id> capture setup --agent codex \
  --project <project-id> --task <task-id> --confirm --install-worker
```

`--install-worker` explicitly requests the local background uploader service on
macOS. The picker previews that request before confirmation. Omitting it approves
local queuing only; run the explicit worker setup before claiming automatic
healthy delivery. The CLI owns service installation and runtime-hash checks.

The user-owned consent ledger is outside the repository. Cloning an enabled
`.keito/config.yml` never approves collection. Changed or inaccessible mappings
hold uploads rather than choosing another client. Legacy config is a mapping
hint only; installation does not backfill historical sessions.

## Lifecycle and controls

| Harness event | Local capture operation |
| --- | --- |
| SessionStart | Preserve/open exact session identity |
| UserPromptSubmit | Open the observed turn |
| Stop | Checkpoint the completed turn |
| Codex Interrupt / Claude StopFailure | Preserve incomplete interval evidence |
| SessionEnd | Finalize without inventing a missing stop time |

`hooks/session-end.sh` remains a compatibility alias for **Stop**, because old
installations registered that filename at turn end. Actual SessionEnd uses
`session-finalize.sh`. All scripts are thin delegates; none calculates duration,
searches another session, reads transcripts or submits ordinary time entries.
The watchdog budgets TERM at 650 ms and KILL 25 ms later, leaving launch/cleanup margin inside the one-second host deadline. A timeout or
failure requires inspecting CLI status; silence does not mean delivery passed.

```bash
keito capture status --json
keito capture preview --session <session-id> --json
keito capture sync
keito capture pause --repo
keito capture resume --repo
keito capture disable --repo
keito-time-track/installers/uninstall.sh --agent codex
```

Installers first durably publish a checksummed hidden generation under the
selected harness's `.keito-capture-generations` directory. Registered commands
point there; a version update never overwrites an executable used by an existing
registration. The JSON switch precedes replacement of the discoverable skill.
A private journal restores interrupted skill discovery on the next invocation,
including after SIGKILL. Normal termination also performs recovery. Immutable
generations remain available across each publication boundary.

Uninstall removes recognized integration-owned registrations and an unmodified
installed discovery payload. Generations are deliberately retained for recovery
and rollback; review all remaining configurations before manually removing them.
Commands that merely mention an adapter path, or combine it with another
executable, are preserved for review rather than silently deleted. Unrelated hooks
remain intact even when they share a registration group.
Modified files, malformed settings, symlinked harness/skills parents or leaves, and concurrent installation fail
with recovery instructions. Configuration replacement is atomic per file;
unrelated applications do not participate in the installer's lock, so review a
reported concurrent-change conflict before retrying. No API keys or raw event
payloads are stored in the installer manifest.

Repository setup holds a separate local lock and records private recovery data
before publishing its candidate hint. A core refusal restores the exact previous
hint, including a disabled mapping. SIGTERM restores it; the next setup recovers
a SIGKILL journal without replaying consent, then stops for status inspection.
If core consent committed just before failure, the restored hint differs from
that binding and the CLI holds capture until explicit review/reapproval. A
concurrent external mapping edit is preserved and reported instead of overwritten.

## Claude plugin candidate

The root `hooks/hooks.json` supplies the same five Claude lifecycle boundaries.
Plugin installation uses Claude's normal marketplace workflow; do not combine
it with direct installation. Plugin hooks use `KEITO_HARNESS_VERSION` when set,
otherwise `unknown`; an unknown version cannot satisfy the real-harness release
gate. Direct installation pins the observed version in its registered command.

## Privacy and financial meaning

Raw hook JSON flows only through transient local stdin to the CLI allowlist.
These scripts never persist it, read the transcript path or emit CLI output into
model context. Default outbound evidence excludes prompts, assistant prose,
code, full paths, branches and secrets. Exact observed duration may include tool
or approval waits within a turn; it is not human effort or vendor cost.

New capture must remain nonbillable pending server-authorized review. Token
usage, estimated provider cost, actual expenditure and client charges are
separate facts. Installing these adapters proves none of those financial facts.
See the qualified product release and review UI before claiming a working
end-to-end billing workflow.

## Local verification

```bash
tests/run.sh
find keito-time-track tests -name '*.sh' -print0 | xargs -0 -n1 bash -n
find keito-time-track tests -name '*.sh' -print0 | xargs -0 shellcheck -P keito-time-track
npx --yes skills-ref@0.1.5 validate keito-time-track
jq empty .claude-plugin/plugin.json .claude-plugin/marketplace.json hooks/hooks.json
```

Tests use temporary HOME, synthetic events and a fake CLI. They cover adapter
boundaries, fail-open behavior, installation preservation and rollback; they do
not qualify real Claude/Codex, database races, network delivery or invoices.
