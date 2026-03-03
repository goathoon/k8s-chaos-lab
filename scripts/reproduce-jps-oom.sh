#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-chaos-lab}"
POD="${POD:-$(kubectl -n "${NAMESPACE}" get pod -l app=direct-memory-lab -o jsonpath='{.items[0].metadata.name}')}"
LOOPS="${LOOPS:-30}"

if [[ -z "${POD}" ]]; then
  echo "pod not found" >&2
  exit 1
fi

echo "[reproduce] pod=${POD} loops=${LOOPS}"

i=1
while [[ $i -le $LOOPS ]]; do
  echo "----- loop ${i} -----"
  kubectl -n "${NAMESPACE}" exec "${POD}" -- sh -c 'date; jps -lv || true; ps -o pid,rss,cmd -p 1 || true'
  kubectl -n "${NAMESPACE}" get pod "${POD}" -o custom-columns=NAME:.metadata.name,PHASE:.status.phase,RESTARTS:.status.containerStatuses[0].restartCount
  sleep 2
  i=$((i+1))
done
