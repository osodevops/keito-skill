#!/usr/bin/env bash
# Development-only delegates. Core filesystem/fault conformance lives in Rust.
set -euo pipefail
repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
# shellcheck source=tests/helpers/isolated-profile.sh
source "$repo/tests/helpers/isolated-profile.sh"
fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT
fixture=$(cd "$fixture" && pwd -P)
mkdir -p "$fixture/home" "$fixture/capture"
export HOME="$fixture/home" CODEX_HOME="$fixture/home/.codex"
export CLAUDE_CONFIG_DIR="$fixture/home/.claude"
export XDG_CONFIG_HOME="$fixture/home/.config" XDG_DATA_HOME="$fixture/home/.local/share"
export XDG_CACHE_HOME="$fixture/home/.cache" KEITO_CAPTURE_HOME="$fixture/capture"
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null
[ "$(cd "$HOME" && pwd -P)" = "$fixture/home" ] || exit 1
export KEITO_CLI_BIN="$fixture/core" KEITO_SHELL_TEST_CALLS="$fixture/calls"
export KEITO_SHELL_TEST_SETUP_MARKER="$fixture/setup-called"
cat > "$KEITO_CLI_BIN" <<'CORE'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$KEITO_SHELL_TEST_CALLS"
case "$*" in
  '--json auth status') printf '%s\n' '{"authenticated":true,"api_key_valid":true,"account_id":"w1"}' ;;
  '--json --workspace w1 clients list') printf '%s\n' '[{"id":"c1","name":"Synthetic client"}]' ;;
  '--json --workspace w1 projects list --client c1') printf '%s\n' '[{"id":"p1","name":"Synthetic project"}]' ;;
  '--json --workspace w1 projects tasks p1') printf '%s\n' '[{"id":"t1","name":"Synthetic task"}]' ;;
  '--workspace w1 capture setup '*) printf ran > "$KEITO_SHELL_TEST_SETUP_MARKER" ;;
esac
CORE
chmod 700 "$KEITO_CLI_BIN"
for agent in codex claude-code; do
  keito_isolated_run "$fixture" bash "$repo/keito-time-track/installers/install-$agent.sh" --confirm-migration
  expected=$(printf 'skill\ninstall\n--agent\n%s\n--confirm-migration' "$agent")
  [ "$(cat "$fixture/calls")" = "$expected" ]
done
keito_isolated_run "$fixture" bash "$repo/keito-time-track/installers/install.sh" --agent codex
[ "$(cat "$fixture/calls")" = $'skill\ninstall\n--agent\ncodex' ]
keito_isolated_run "$fixture" bash "$repo/keito-time-track/installers/uninstall.sh" --agent codex
[ "$(cat "$fixture/calls")" = $'skill\nuninstall\n--agent\ncodex' ]
for event in session-start prompt stop interrupt session-end; do
  export KEITO_CAPTURE_GUARD_BIN="$fixture/guard"
  cat > "$KEITO_CAPTURE_GUARD_BIN" <<'GUARD'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$KEITO_SHELL_TEST_CALLS"
cat >/dev/null
GUARD
  chmod 700 "$KEITO_CAPTURE_GUARD_BIN"
  output=$(printf '%s' '{"private":"discard"}' | keito_isolated_run "$fixture" bash "$repo/keito-time-track/hooks/dispatch.sh" --agent codex --event "$event" --harness-version 0.167.0 2>&1)
  [ -z "$output" ]
  expected=$(printf -- '--core\n%s\n--agent\ncodex\n--event\n%s\n--harness-version\n0.167.0' "$KEITO_CLI_BIN" "$event")
  [ "$(cat "$fixture/calls")" = "$expected" ]
done
rm "$fixture/calls"
KEITO_CAPTURE_GUARD_BIN=relative keito_isolated_run "$fixture" bash "$repo/keito-time-track/hooks/dispatch.sh" --agent codex --event stop --harness-version 0.167.0
[ ! -e "$fixture/calls" ]
for spec in status pause resume disable; do
  case "$spec" in
    status) script=scripts/status.sh; args=(); expected=$'capture\nstatus' ;;
    pause|resume) script=scripts/pause-resume.sh; args=("$spec"); expected=$(printf 'capture\n%s\n--repo' "$spec") ;;
    disable) script=scripts/disable.sh; args=(); expected=$'capture\ndisable\n--repo' ;;
  esac
  keito_isolated_run "$fixture" bash "$repo/keito-time-track/$script" ${args[@]+"${args[@]}"}
  [ "$(cat "$fixture/calls")" = "$expected" ]
done
mkdir "$fixture/repository"
keito_isolated_run "$fixture" git -c init.templateDir= init --quiet "$fixture/repository"
for worker in no yes; do
  options=(); [ "$worker" = no ] || options=(--install-worker)
  (cd "$fixture/repository"; printf '1\n1\n1\ny\n' | keito_isolated_run "$fixture" bash "$repo/keito-time-track/scripts/setup-wizard.sh" --agent codex ${options[@]+"${options[@]}"}) > "$fixture/setup-output"
  [ -f "$fixture/setup-called" ]
  expected=$'--workspace\nw1\ncapture\nsetup\n--client\nc1\n--project\np1\n--task\nt1\n--write-hint\n--agent\ncodex'
  if [ "$worker" = yes ]; then
    expected+=$'\n--install-worker'
    grep -q 'background uploader' "$fixture/setup-output"
  fi
  expected+=$'\n--confirm'
  [ "$(cat "$fixture/calls")" = "$expected" ]
  [ ! -e "$fixture/repository/.keito/config.yml" ]
  rm "$fixture/setup-called"
done
(cd "$fixture/repository"; printf '1\n1\n1\nn\n' | keito_isolated_run "$fixture" bash "$repo/keito-time-track/scripts/setup-wizard.sh" --agent codex) > "$fixture/cancel-output"
[ ! -e "$fixture/setup-called" ]
if keito_isolated_run "$fixture" bash "$repo/keito-time-track/scripts/setup-wizard.sh" > /dev/null 2>&1; then exit 1; fi
[ ! -e "$fixture/setup-called" ]
printf '%s\n' 'Native shell delegation, scoped setup, cancellation and explicit-worker checks passed.'
