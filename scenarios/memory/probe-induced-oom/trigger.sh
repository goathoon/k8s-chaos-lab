#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../../scripts/lib/scenario.sh" "memory/probe-induced-oom"

namespace="$(scenario_namespace)"
pod="$(scenario_pod)"
loops="${LOOPS:-30}"

echo "[trigger] pod=${pod} loops=${loops}"

for ((i=1; i<=loops; i++)); do
  echo "----- loop ${i} -----"
  kubectl -n "${namespace}" exec "${pod}" -- sh -c 'date; jps -lv || true; ps -o pid,rss,cmd -p 1 || true'
  kubectl -n "${namespace}" get pod "${pod}" -o custom-columns=NAME:.metadata.name,PHASE:.status.phase,RESTARTS:.status.containerStatuses[0].restartCount
  sleep 2
done
