#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../../scripts/lib/scenario.sh" "k8s/bad-readiness"

namespace="$(scenario_namespace)"
pod="$(scenario_pod)"
ready="$(kubectl -n "${namespace}" get pod "${pod}" -o jsonpath='{.status.containerStatuses[0].ready}')"

echo "[verify] pod=${pod} ready=${ready}"
kubectl -n "${namespace}" describe pod "${pod}" | rg -n "Readiness probe failed|ready" || true

if [[ "${ready}" != "false" ]]; then
  echo "[verify] expected pod to remain unready" >&2
  exit 1
fi
