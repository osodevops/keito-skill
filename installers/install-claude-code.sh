#!/usr/bin/env bash
set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required to merge Claude Code hook settings." >&2
  exit 1
fi

source_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
dest="$HOME/.claude/skills/keito-time-track"
settings="$HOME/.claude/settings.json"

mkdir -p "$(dirname "$dest")" "$(dirname "$settings")"
rm -rf "$dest"
cp -R "$source_dir" "$dest"

[ -f "$settings" ] || printf '{}\n' > "$settings"
start_cmd="KEITO_AGENT_TYPE=claude-code $dest/hooks/session-start.sh"
end_cmd="KEITO_AGENT_TYPE=claude-code $dest/hooks/session-end.sh"

jq \
  --arg start "$start_cmd" \
  --arg end "$end_cmd" \
  '
  .hooks = (.hooks // {}) |
  .hooks.SessionStart = (
    (.hooks.SessionStart // [])
    | map(select((.hooks // [] | map(.command // "") | index($start)) == null))
    + [{
      matcher: "*",
      hooks: [{ type: "command", command: $start }]
    }]
  ) |
  .hooks.Stop = (
    (.hooks.Stop // [])
    | map(select((.hooks // [] | map(.command // "") | index($end)) == null))
    + [{
      hooks: [{ type: "command", command: $end, timeout: 30 }]
    }]
  )
  ' "$settings" > "$settings.tmp"
mv "$settings.tmp" "$settings"

chmod +x "$dest/hooks/session-start.sh" "$dest/hooks/session-end.sh" "$dest/scripts/"*.sh

echo "Installed Keito Time Track skill for Claude Code:"
echo "  $dest"
echo "Updated hooks:"
echo "  $settings"
