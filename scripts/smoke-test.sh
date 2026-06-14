#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-swimlane}"
LOCAL_PORT="${LOCAL_PORT:-3000}"

kubectl -n "${NAMESPACE}" port-forward service/swimlane-app "${LOCAL_PORT}:80" >/tmp/swimlane-port-forward.log 2>&1 &
PF_PID=$!
trap 'kill ${PF_PID} >/dev/null 2>&1 || true' EXIT

for _ in $(seq 1 30); do
  if curl -fsS "http://127.0.0.1:${LOCAL_PORT}/healthz" >/dev/null 2>&1; then
    curl -fsS "http://127.0.0.1:${LOCAL_PORT}/" >/dev/null
    echo "Smoke test passed: http://127.0.0.1:${LOCAL_PORT}"
    exit 0
  fi
  sleep 2
done

echo "Smoke test failed. Port-forward log:"
cat /tmp/swimlane-port-forward.log
exit 1
