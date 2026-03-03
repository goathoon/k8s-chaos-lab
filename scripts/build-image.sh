#!/usr/bin/env bash
set -euo pipefail

PROFILE="${MINIKUBE_PROFILE:-chaos-lab}"
IMAGE_NAME="${IMAGE_NAME:-direct-memory-lab:local}"

minikube -p "${PROFILE}" image build -t "${IMAGE_NAME}" .

echo "[build-image] built ${IMAGE_NAME} into minikube profile ${PROFILE}"
