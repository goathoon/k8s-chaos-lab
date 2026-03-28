#!/usr/bin/env bash
set -euo pipefail

SCENARIO_NAME="${1:-${SCENARIO:-}}"
source "$(dirname "$0")/lib/scenario.sh" "${SCENARIO_NAME}"

namespace="$(scenario_namespace)"
deployment="$(scenario_deployment)"
rollout_mode="$(scenario_rollout_mode)"

echo "[scenario] apply ${scenario_name}"
echo "[scenario] description=$(scenario_description)"
kubectl apply -k "${scenario_dir}"

if [[ "${rollout_mode}" == "stable" ]]; then
  kubectl -n "${namespace}" rollout status "deployment/${deployment}" --timeout=180s
else
  echo "[scenario] rollout check skipped (mode=${rollout_mode})"
fi

kubectl -n "${namespace}" get pods -o wide
