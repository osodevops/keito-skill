# Security policy

Report suspected vulnerabilities privately to Keito maintainers. Share only
sanitized reproduction details; never include credentials, raw hook events,
transcripts, customer content or real mapping identifiers.

The CLI bundle is the default distribution. A release must identify exact CLI,
adapter and harness artifacts and renew host trust when required. Portable
adapters are not an npm package. Optional open skills installation must use the
pinned `skills@1.5.6` package; workflow actions use full commit SHAs and read-only
repository permissions.

These adapters pass raw harness JSON only through transient local stdin into the
allowlisting CLI. They do not write payloads/logs or read transcript files. The
CLI owns metadata-only SQLite durability and explicit repository consent.
Installation must not enable Codex features or grant hook trust automatically.

Malformed settings, unexpected symlinks and modified payloads require explicit
local recovery. Parent directories below the resolved approved HOME must also
be regular directories; ordinary macOS HOME aliases are allowed. Installers
publish immutable executable generations before switching configuration and
journal discoverable-payload changes for signal/restart recovery. Generations
and legacy backups remain available for reviewed recovery. Mapping setup uses
a separate lock/journal and restores its previous hint on failure. A potentially
committed core consent is inspected and reapproved explicitly, never replayed. An installer manifest states trust unknown and delivery
unverified. It never stores API keys or proves billing approval.

Run the temp-HOME tests and checks in CONTRIBUTING.md before release. Real
harness qualification and platform authorization/privacy tests remain required.
