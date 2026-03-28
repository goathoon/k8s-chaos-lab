#!/usr/bin/env bash
set -euo pipefail

SCENARIO_NAME="${1:-${SCENARIO:-}}"
source "$(dirname "$0")/lib/scenario.sh" "${SCENARIO_NAME}"

echo "[scenario] delete ${scenario_name}"
kubectl delete -k "${scenario_dir}" --ignore-not-found=true
