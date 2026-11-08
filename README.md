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
keito-time-track/scripts/setup-wizard.sh --agent claude-code --agent codex
```

For scripted setup, use the CLI directly with explicit project/task IDs and
confirmation after inspecting the capture policy:

```bash
keito --workspace <workspace-id> capture setup --agent codex \
  --project <project-id> --task <task-id> --confirm
```

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
A one-second watchdog prevents a stalled CLI from blocking coding. A timeout or
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

Uninstall removes integration-owned registrations and an unmodified installed
payload. It preserves unrelated hooks even when they share a registration group.
Modified files, malformed settings, symlinks and concurrent installation fail
with recovery instructions. Configuration replacement is atomic per file;
unrelated applications do not participate in the installer's lock, so review a
reported concurrent-change conflict before retrying. No API keys or raw event
payloads are stored in the installer manifest.

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
