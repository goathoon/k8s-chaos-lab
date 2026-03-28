#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../../scripts/lib/scenario.sh" "k8s/crashloop"

namespace="$(scenario_namespace)"
pod="$(scenario_pod)"
waiting_reason="$(kubectl -n "${namespace}" get pod "${pod}" -o jsonpath='{.status.containerStatuses[0].state.waiting.reason}')"

echo "[verify] pod=${pod} waiting_reason=${waiting_reason}"
kubectl -n "${namespace}" logs "${pod}" --previous || true

if [[ "${waiting_reason}" != "CrashLoopBackOff" ]]; then
  echo "[verify] expected CrashLoopBackOff waiting reason" >&2
  exit 1
fi
