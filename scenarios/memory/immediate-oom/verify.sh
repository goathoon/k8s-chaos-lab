#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../../scripts/lib/scenario.sh" "memory/immediate-oom"

namespace="$(scenario_namespace)"
pod=""
restarts="0"
oom_seen="false"

for _ in {1..20}; do
  pod="$(scenario_pod)"
  if [[ -n "${pod}" ]]; then
    restarts="$(kubectl -n "${namespace}" get pod "${pod}" -o jsonpath='{.status.containerStatuses[0].restartCount}')"
    if kubectl -n "${namespace}" describe pod "${pod}" | rg -q "OOMKilled"; then
      oom_seen="true"
    fi

    if [[ "${restarts}" -ge 1 || "${oom_seen}" == "true" ]]; then
      break
    fi
  fi
  sleep 2
done

echo "[verify] pod=${pod} restarts=${restarts} oom_seen=${oom_seen}"
kubectl -n "${namespace}" describe pod "${pod}" | rg -n "OOMKilled|Reason:|Last State" || true

if [[ "${restarts}" -lt 1 && "${oom_seen}" != "true" ]]; then
  echo "[verify] expected rapid OOM restart after startup" >&2
  exit 1
fi
