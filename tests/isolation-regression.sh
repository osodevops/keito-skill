#!/usr/bin/env bash
set -euo pipefail
repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
# shellcheck source=tests/helpers/isolated-profile.sh
source "$repo/tests/helpers/isolated-profile.sh"
fixture=$(mktemp -d)
other_fixture=$(mktemp -d)
trap 'rm -rf "$fixture" "$other_fixture"' EXIT
fixture=$(cd "$fixture" && pwd -P)
other_fixture=$(cd "$other_fixture" && pwd -P)
mkdir -p "$fixture/home" "$fixture/foreign" "$fixture/capture"
export HOME="$fixture/home" CODEX_HOME="$fixture/home/.codex" CLAUDE_CONFIG_DIR="$fixture/home/.claude"
export KEITO_CAPTURE_HOME="$fixture/capture" KEITO_CLI_BIN="$fixture/core" KEITO_TEST_MUTATION_MARKER="$fixture/mutated"
cat > "$fixture/core" <<'CORE'
#!/usr/bin/env bash
printf ran > "$KEITO_TEST_MUTATION_MARKER"
CORE
chmod 700 "$fixture/core"
for profile in '' "$fixture/foreign"; do
  if (export HOME="$profile"; keito_isolated_run "$fixture" "$fixture/core"); then
    echo 'Unsafe profile reached the mutation entrypoint.' >&2
    exit 1
  fi
  [ ! -e "$fixture/mutated" ]
done
if (unset HOME; keito_isolated_run "$fixture" "$fixture/core"); then exit 1; fi
[ ! -e "$fixture/mutated" ]
if (unset KEITO_CAPTURE_HOME; keito_isolated_run "$fixture" "$fixture/core"); then exit 1; fi
[ ! -e "$fixture/mutated" ]
if (export KEITO_CLI_BIN=keito; keito_isolated_run "$fixture" "$fixture/core"); then exit 1; fi
[ ! -e "$fixture/mutated" ]
for harness in .codex .claude; do
  mkdir -p "$other_fixture/$harness"
  ln -s "$other_fixture/$harness" "$fixture/home/$harness"
  if keito_isolated_run "$fixture" "$fixture/core"; then exit 1; fi
  [ ! -e "$fixture/mutated" ]
  rm "$fixture/home/$harness"
  mkdir "$fixture/home/$harness"
done
keito_isolated_run "$fixture" "$fixture/core"
[ "$(cat "$fixture/mutated")" = ran ]
printf '%s\n' 'Missing/foreign profile refuses before mutation; explicit fixture succeeds.'
