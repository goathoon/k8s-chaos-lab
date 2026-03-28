#!/usr/bin/env bash
set -euo pipefail

SCENARIO_NAME="${1:-${SCENARIO:-}}"
source "$(dirname "$0")/lib/scenario.sh" "${SCENARIO_NAME}"

trigger_script="$(scenario_trigger_script)"

if scenario_exists_script "${trigger_script}"; then
  "${trigger_script}" "${scenario_name}"
else
  echo "[scenario] no trigger script for ${scenario_name}"
fi
