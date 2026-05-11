#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
# shellcheck disable=SC1091
# shellcheck source=../hooks/lib/log.sh
. "$script_dir/../hooks/lib/log.sh"
# shellcheck disable=SC1091
# shellcheck source=../hooks/lib/config.sh
. "$script_dir/../hooks/lib/config.sh"

cwd=$(pwd -P)
config_path=$(keito_find_config "$cwd" 2>/dev/null || true)

if [ -z "$config_path" ]; then
  echo "Keito tracking: untracked"
  echo "No .keito/config.yml found at or above $cwd"
  exit 0
fi

echo "Keito tracking: configured"
echo "Config: $config_path"
echo "Project: $(keito_yaml_get "$config_path" "project_name" "$(keito_yaml_get "$config_path" "project_id" "")")"
echo "Task: $(keito_yaml_get "$config_path" "task_name" "$(keito_yaml_get "$config_path" "task_id" "")")"
echo "Enabled: $(keito_yaml_get "$config_path" "agent_tracking.enabled" "true")"
echo "Source: $(keito_yaml_get "$config_path" "agent_tracking.source" "agent")"
echo "Min duration: $(keito_yaml_get "$config_path" "agent_tracking.min_duration_seconds" "60")s"

state_file=$(keito_latest_state_for_cwd "$cwd" 2>/dev/null || true)
if [ -n "$state_file" ] && [ -f "$state_file" ]; then
  started_epoch=$(jq -r '.started_epoch // empty' "$state_file")
  session_id=$(jq -r '.session_id // empty' "$state_file")
  paused=$(jq -r '.paused // false' "$state_file")
  now=$(date -u +%s)
  elapsed=0
  if [[ "$started_epoch" =~ ^[0-9]+$ ]]; then
    elapsed=$((now - started_epoch))
  fi
  echo "Current session: $session_id (${elapsed}s elapsed, paused=$paused)"
else
  echo "Current session: none recorded"
fi

if command -v keito >/dev/null 2>&1; then
  echo
  echo "Today's agent entries:"
  keito --json time list --today --source agent --limit 20 2>/dev/null || echo "Unable to query Keito CLI."
fi
