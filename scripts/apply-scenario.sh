#!/usr/bin/env bash
set -euo pipefail

SCENARIO="${1:-fixed-256m}"
FILE="k8s/${SCENARIO}.yaml"

if [[ ! -f "${FILE}" ]]; then
  echo "scenario file not found: ${FILE}" >&2
  exit 1
fi

kubectl apply -f "${FILE}"
kubectl -n chaos-lab rollout status deployment/direct-memory-lab --timeout=180s
kubectl -n chaos-lab get pods -o wide
