#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

export HOME="$tmp/home"
export KEITO_SKILL_HOME="$tmp/skill-home"
mkdir -p "$HOME" "$KEITO_SKILL_HOME" "$tmp/bin" "$tmp/repo/.keito"

cat > "$tmp/repo/.keito/config.yml" <<'YAML'
version: 1
workspace_id: co_test
project_id: p1
project_name: "Project A"
task_id: t1
task_name: "Development"
agent_tracking:
  enabled: true
  source: agent
  draft: true
  min_duration_seconds: 60
  max_duration_seconds: 28800
  redact_notes: false
metadata:
  env: test
YAML

cat > "$tmp/bin/keito" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$KEITO_FAKE_CALLS"
case "$*" in
  *"time session-record"*)
    printf '{"status":"created","entry_id":"te_test","source":"agent","session_id":"sess_test"}\n'
    ;;
  *"auth status"*)
    printf '{"authenticated":true,"api_key_valid":true,"account_id":"co_test"}\n'
    ;;
  *"clients list"*)
    printf '[{"id":"c1","name":"Client A"}]\n'
    ;;
  *"clients create"*)
    printf '{"id":"c_new","name":"New Client"}\n'
    ;;
  *"projects list"*"--client c_new"*)
    printf '[]\n'
    ;;
  *"projects list"*)
    printf '[{"id":"p1","name":"Project A","code":"PA"}]\n'
    ;;
  *"projects create"*)
    if [ "${KEITO_FAKE_BAD_PROJECT_CREATE:-}" = "1" ]; then
      printf '{"name":"New Project"}\n'
      exit 0
    fi
    printf '{"id":"p_new","name":"New Project","client":{"id":"c_new","name":"New Client"}}\n'
    ;;
  *"projects tasks"*)
    printf '[{"id":"t1","name":"Development"}]\n'
    ;;
  *"time list"*)
    printf '[]\n'
    ;;
  *)
    printf '{}\n'
    ;;
esac
SH
chmod +x "$tmp/bin/keito"

export PATH="$tmp/bin:$PATH"
export KEITO_FAKE_CALLS="$tmp/keito-calls.log"

payload=$(jq -n --arg cwd "$tmp/repo" --arg session_id "sess_test" \
  '{cwd: $cwd, session_id: $session_id, last_assistant_message: "Implemented a local test feature."}')

"$repo_root/hooks/session-start.sh" <<< "$payload"
state_file=$(find "$KEITO_SKILL_HOME/sessions" -type f -name '*.json' | head -n 1)
[ -f "$state_file" ]

jq '.started_epoch = (.started_epoch - 65)' "$state_file" > "$state_file.tmp"
mv "$state_file.tmp" "$state_file"

"$repo_root/hooks/session-end.sh" <<< "$payload"

if find "$KEITO_SKILL_HOME/sessions" -type f -name '*.json' | grep -q .; then
  echo "Expected session state to be removed after successful logging" >&2
  exit 1
fi

grep -q -- "time session-record" "$KEITO_FAKE_CALLS"
grep -q -- "--workspace co_test" "$KEITO_FAKE_CALLS"
grep -q -- "--project p1" "$KEITO_FAKE_CALLS"
grep -q -- "--task t1" "$KEITO_FAKE_CALLS"
grep -q -- "--session-id sess_test" "$KEITO_FAKE_CALLS"
grep -q -- "--source agent" "$KEITO_FAKE_CALLS"

short_payload=$(jq -n --arg cwd "$tmp/repo" --arg session_id "short_session" \
  '{cwd: $cwd, session_id: $session_id}')
"$repo_root/hooks/session-start.sh" <<< "$short_payload"
"$repo_root/hooks/session-end.sh" <<< "$short_payload"
if grep -q -- "short_session" "$KEITO_FAKE_CALLS"; then
  echo "Expected short session to be skipped" >&2
  exit 1
fi

mkdir -p "$tmp/setup-repo"
(
  cd "$tmp/setup-repo"
  printf '1\n1\n1\nY\n' | "$repo_root/scripts/setup-wizard.sh" >/dev/null
)
[ -f "$tmp/setup-repo/.keito/config.yml" ]
grep -q -- "client_id: c1" "$tmp/setup-repo/.keito/config.yml"
grep -q -- "project_id: p1" "$tmp/setup-repo/.keito/config.yml"
grep -q -- "task_id: t1" "$tmp/setup-repo/.keito/config.yml"

mkdir -p "$tmp/setup-create-repo"
(
  cd "$tmp/setup-create-repo"
  printf '2\nNew Client\n1\nNew Project\n1\nY\n' | "$repo_root/scripts/setup-wizard.sh" >/dev/null
)
[ -f "$tmp/setup-create-repo/.keito/config.yml" ]
grep -q -- "client_id: c_new" "$tmp/setup-create-repo/.keito/config.yml"
grep -q -- "project_id: p_new" "$tmp/setup-create-repo/.keito/config.yml"

mkdir -p "$tmp/setup-fail-repo"
set +e
(
  cd "$tmp/setup-fail-repo"
  printf '2\nNew Client\n1\nNew Project\n' | KEITO_FAKE_BAD_PROJECT_CREATE=1 "$repo_root/scripts/setup-wizard.sh" >/dev/null 2>"$tmp/setup-fail.err"
)
setup_fail_status=$?
set -e
if [ "$setup_fail_status" -eq 0 ]; then
  echo "Expected setup wizard to fail when project create response has no id" >&2
  exit 1
fi
if [ -e "$tmp/setup-fail-repo/.keito/config.yml" ]; then
  echo "Expected setup wizard not to write config after failed project creation" >&2
  exit 1
fi
grep -q -- "created project id" "$tmp/setup-fail.err"

echo "skill hook tests passed"
