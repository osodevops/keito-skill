#!/usr/bin/env bash
# Development-only boundary: refuse an incomplete/foreign profile before spawn.
keito_require_isolated_profile() {
  local fixture=$1 canonical_fixture canonical_home
  [ -n "$fixture" ] && [ -d "$fixture" ] && [ ! -L "$fixture" ] || return 1
  canonical_fixture=$(cd "$fixture" && pwd -P) || return 1
  [ "$fixture" = "$canonical_fixture" ] || return 1
  [ -n "${HOME:-}" ] && [ -d "$HOME" ] && [ ! -L "$HOME" ] || return 1
  canonical_home=$(cd "$HOME" && pwd -P) || return 1
  [ "$canonical_home" = "$fixture/home" ] || return 1
  [ "${CODEX_HOME:-}" = "$fixture/home/.codex" ] || return 1
  [ "${CLAUDE_CONFIG_DIR:-}" = "$fixture/home/.claude" ] || return 1
  local harness
  for harness in "$CODEX_HOME" "$CLAUDE_CONFIG_DIR"; do
    [ ! -L "$harness" ] || return 1
    if [ -e "$harness" ]; then
      [ -d "$harness" ] || return 1
      [ "$(cd "$harness" && pwd -P)" = "$harness" ] || return 1
    fi
  done
  [ "${KEITO_CAPTURE_HOME:-}" = "$fixture/capture" ] || return 1
  [ -d "$KEITO_CAPTURE_HOME" ] && [ ! -L "$KEITO_CAPTURE_HOME" ] || return 1
  [ "$(cd "$KEITO_CAPTURE_HOME" && pwd -P)" = "$fixture/capture" ] || return 1
  [ "${KEITO_CLI_BIN:-}" = "$fixture/core" ] || return 1
  [ -f "$KEITO_CLI_BIN" ] && [ -x "$KEITO_CLI_BIN" ] && [ ! -L "$KEITO_CLI_BIN" ] || return 1
}
keito_isolated_run() {
  local fixture=$1
  shift
  keito_require_isolated_profile "$fixture" || { echo 'Refusing test invocation: an explicit isolated profile and fake CLI are required.' >&2; return 97; }
  "$@"
}
keito_global_profile_fingerprint() {
  local profile=$1 file
  [ -n "$profile" ] && [ -d "$profile" ] || return 1
  for file in "$profile/.codex/hooks.json" "$profile/.claude/settings.json"; do
    [ ! -L "$file" ] || return 1
    if [ -f "$file" ]; then
      # Only a digest is retained; no configuration body is emitted.
      shasum -a 256 < "$file" || return 1
    elif [ ! -e "$file" ]; then
      printf '%s\n' 'MISSING'
    else
      return 1
    fi
  done
}
