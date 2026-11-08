#!/usr/bin/env bash
set -euo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
# shellcheck source=tests/helpers/isolated-profile.sh
source "$repo_root/tests/helpers/isolated-profile.sh"
real_profile=${KEITO_TEST_REAL_PROFILE_HOME:-${HOME:?An explicit original profile anchor is required}}
baseline=$(keito_global_profile_fingerprint "$real_profile") || exit 1
readonly real_profile baseline
verify_baseline() {
  local result=$? after
  after=$(keito_global_profile_fingerprint "$real_profile") || result=98
  if [ "$after" != "$baseline" ]; then
    echo 'Global profile changed during local verification; stop and preserve evidence.' >&2
    result=98
  fi
  exit "$result"
}
trap verify_baseline EXIT
bash "$repo_root/tests/isolation-regression.sh"
bash "$repo_root/tests/adapter-shells.sh"
