#!/bin/bash
# Force delete all static PVCs

PVCS=(
  "prod-consul:prod-consul-stack"
  "prod-loki:prod-loki-system"
  "prod-homebridge:prod-homebridge-system"
  "prod-n8n:prod-n8n-system"
  "prod-openhab:prod-openhab-system"
  "prod-portainer:prod-portainer-system"
  "prod-home-assistant:prod-home-assistant-system"
)

for item in "${PVCS[@]}"; do
  PVC="${item%%:*}"
  NS="${item##*:}"
  echo "Deleting $PVC in $NS..."
  kubectl patch pvc "$PVC" -n "$NS" -p '{"metadata":{"finalizers":null}}' --type=merge 2>/dev/null
  kubectl delete pvc "$PVC" -n "$NS" --force --grace-period=0 2>/dev/null
done

echo "Done. Now delete static PVs:"
kubectl delete pv prod-consul prod-loki prod-homebridge prod-n8n prod-openhab prod-portainer prod-home-assistant --ignore-not-found=true
