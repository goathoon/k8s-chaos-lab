#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../../scripts/lib/scenario.sh" "memory/direct-oom"

namespace="$(scenario_namespace)"
pod="$(scenario_pod)"
restarts="$(kubectl -n "${namespace}" get pod "${pod}" -o jsonpath='{.status.containerStatuses[0].restartCount}')"

echo "[verify] pod=${pod} restarts=${restarts}"
kubectl -n "${namespace}" describe pod "${pod}" | rg -n "OOMKilled|Reason:|Last State" || true

if [[ "${restarts}" -lt 1 ]]; then
  echo "[verify] expected at least one restart from OOM pressure" >&2
  exit 1
fi
