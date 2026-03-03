#!/usr/bin/env bash
set -euo pipefail

PROFILE="${MINIKUBE_PROFILE:-chaos-lab}"
K8S_VERSION="${K8S_VERSION:-v1.30.0}"
CPUS="${MINIKUBE_CPUS:-4}"
MEMORY="${MINIKUBE_MEMORY:-8192}"
DISK="${MINIKUBE_DISK:-20g}"

minikube start \
  --profile "${PROFILE}" \
  --kubernetes-version "${K8S_VERSION}" \
  --cpus "${CPUS}" \
  --memory "${MEMORY}" \
  --disk-size "${DISK}" \
  --driver docker

kubectl create namespace chaos-lab --dry-run=client -o yaml | kubectl apply -f -

cat <<MSG
[minikube-up] profile=${PROFILE}
[minikube-up] namespace=chaos-lab ready
MSG
