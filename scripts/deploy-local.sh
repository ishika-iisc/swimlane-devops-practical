#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-swimlane}"
IMAGE_NAME="${IMAGE_NAME:-swimlane-devops-practical}"
IMAGE_TAG="${IMAGE_TAG:-local}"
KIND_BIN="${KIND_BIN:-kind}"

./scripts/build-image.sh

if KIND_PATH=$(command -v "${KIND_BIN}" 2>/dev/null); then
  if "${KIND_PATH}" get clusters | grep -qx swimlane; then
    "${KIND_PATH}" load docker-image "${IMAGE_NAME}:${IMAGE_TAG}" --name swimlane
  fi
fi

kubectl apply -k k8s/overlays/local
kubectl -n "${NAMESPACE}" rollout status statefulset/mongodb --timeout=180s
kubectl -n "${NAMESPACE}" rollout status deployment/swimlane-app --timeout=180s
