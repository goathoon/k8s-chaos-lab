#!/usr/bin/env bash
set -euo pipefail

SCENARIO_NAME="${1:-${SCENARIO:-}}"
source "$(dirname "$0")/lib/scenario.sh" "${SCENARIO_NAME}"

verify_script="$(scenario_verify_script)"
namespace="$(scenario_namespace)"
deployment="$(scenario_deployment)"

if scenario_exists_script "${verify_script}"; then
  "${verify_script}" "${scenario_name}"
  exit 0
fi

echo "[scenario] no custom verifier for ${scenario_name}; running generic rollout check"
kubectl -n "${namespace}" rollout status "deployment/${deployment}" --timeout=60s
