#!/usr/bin/env bash
set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required to merge Codex hook settings." >&2
  exit 1
fi

source_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
dest="$HOME/.codex/skills/keito-time-track"
hooks="$HOME/.codex/hooks.json"

mkdir -p "$(dirname "$dest")" "$(dirname "$hooks")"
rm -rf "$dest"
cp -R "$source_dir" "$dest"

[ -f "$hooks" ] || printf '{}\n' > "$hooks"
start_cmd="KEITO_AGENT_TYPE=codex $dest/hooks/session-start.sh"
end_cmd="KEITO_AGENT_TYPE=codex $dest/hooks/session-end.sh"

jq \
  --arg start "$start_cmd" \
  --arg end "$end_cmd" \
  '
  .hooks = (.hooks // {}) |
  .hooks.SessionStart = (
    (.hooks.SessionStart // [])
    | map(select((.hooks // [] | map(.command // "") | index($start)) == null))
    + [{
      matcher: "startup|resume",
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
  ' "$hooks" > "$hooks.tmp"
mv "$hooks.tmp" "$hooks"

chmod +x "$dest/hooks/session-start.sh" "$dest/hooks/session-end.sh" "$dest/scripts/"*.sh

echo "Installed Keito Time Track skill for Codex:"
echo "  $dest"
echo "Updated hooks:"
echo "  $hooks"
