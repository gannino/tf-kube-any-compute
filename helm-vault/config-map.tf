resource "kubernetes_config_map" "vault_scripts" {
  metadata {
    name      = "vault-scripts"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels    = local.common_labels
  }

  data = {
    "vault-init.sh" = <<-EOT
#!/bin/sh
set -euo pipefail

# Kubernetes-friendly logging with timestamps
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] INIT: $1"
}

# Wait for Vault container to be ready with exponential backoff
wait_for_vault_ready() {
  local vault_addr="$1"
  local max_wait=${local.module_config.vault_readiness_timeout}  # Configurable readiness timeout
  local wait_time=5
  local elapsed=0

  log "Waiting for Vault container to be ready at $vault_addr..."

  while [ $elapsed -lt $max_wait ]; do
    if curl -sk "$vault_addr/v1/sys/health?standbyok=true" >/dev/null 2>&1; then
      log "Vault container is responding"
      return 0
    fi

    log "Vault not ready yet, waiting $${wait_time}s... (elapsed: $${elapsed}s)"
    sleep $wait_time
    elapsed=$((elapsed + wait_time))

    # Exponential backoff, max 30s
    if [ $wait_time -lt 30 ]; then
      wait_time=$((wait_time * 2))
    fi
  done

  log "ERROR: Vault container did not become ready within ${local.module_config.vault_readiness_timeout}s"
  return 1
}

# Use Vault service for connection from init job
if [ -n "$VAULT_SERVICE" ] && [ -n "$VAULT_NAMESPACE" ]; then
  VAULT_ADDR="http://$VAULT_SERVICE.$VAULT_NAMESPACE.svc.cluster.local:8200"
else
  # Fallback to internal service name
  VAULT_ADDR="http://${local.module_config.name}.${kubernetes_namespace.this.metadata[0].name}.svc.cluster.local:8200"
fi
log "Using VAULT_ADDR=$VAULT_ADDR"

SECRET_NAME="vault-unseal-keys"
SECRET_NS=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)
CACERT=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)

# Wait for Vault container to be ready first
wait_for_vault_ready "$VAULT_ADDR"

# Wait for Vault to be initialized (or ready for initialization)
log "Waiting for Vault to be ready for initialization..."
max_init_wait=${local.module_config.vault_init_timeout}  # Configurable timeout for initialization
init_elapsed=0

while [ $init_elapsed -lt $max_init_wait ]; do
  HEALTH_RESPONSE=$(curl -sk "$VAULT_ADDR/v1/sys/health?standbyok=true" 2>/dev/null || echo '{"initialized":false}')

  if echo "$HEALTH_RESPONSE" | grep -q '"initialized":true'; then
    log "Vault is already initialized"
    break
  elif echo "$HEALTH_RESPONSE" | grep -q '"initialized":false'; then
    log "Vault is ready for initialization"
    break
  fi

  log "Vault not ready for initialization yet. Health response: $HEALTH_RESPONSE"
  sleep 10
  init_elapsed=$((init_elapsed + 10))
done

if [ $init_elapsed -ge $max_init_wait ]; then
  log "ERROR: Vault did not become ready for initialization within ${local.module_config.vault_init_timeout}s"
  exit 1
fi

log "Checking if Vault is already initialized..."
INIT_STATUS=$(curl -sk "$VAULT_ADDR/v1/sys/init" 2>/dev/null || echo '{"initialized":false}')
if echo "$INIT_STATUS" | grep -q '"initialized":true'; then
  log "Vault already initialized. Checking if secret exists..."

  # Verify secret exists before exiting
  SECRET_CHECK=$(curl -sk -w "%%{http_code}" -o /dev/null --cacert "$CACERT" \
    -H "Authorization: Bearer $TOKEN" \
    "https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT/api/v1/namespaces/$SECRET_NS/secrets/$SECRET_NAME")

  if [ "$SECRET_CHECK" = "200" ]; then
    log "Secret $SECRET_NAME exists. Initialization complete."
    exit 0
  else
    log "WARNING: Vault initialized but secret missing. This should not happen in normal operation."
    exit 1
  fi
fi

log "Initializing Vault with 5 shares, threshold 3..."
INIT_RESPONSE=$(curl -sk --request PUT --data '{"secret_shares": 5, "secret_threshold": 3}' "$VAULT_ADDR/v1/sys/init" 2>/dev/null)

if [ -z "$INIT_RESPONSE" ]; then
  log "ERROR: Failed to get response from Vault initialization"
  exit 1
fi

log "Vault initialization completed successfully"

# Normalize INIT_RESPONSE to a single line for easier sed matching
INIT_RESPONSE_CLEAN=$(echo "$INIT_RESPONSE" | tr -d '\n')

ROOT_TOKEN=$(echo "$INIT_RESPONSE_CLEAN" | sed -n 's/.*"root_token":"\([^"]*\)".*/\1/p')
KEY0=$(echo "$INIT_RESPONSE_CLEAN" | sed -n 's/.*"keys_base64":\["\([^"]*\)".*/\1/p')
KEY1=$(echo "$INIT_RESPONSE_CLEAN" | sed -n 's/.*"keys_base64":\["[^"]*","\([^"]*\)".*/\1/p')
KEY2=$(echo "$INIT_RESPONSE_CLEAN" | sed -n 's/.*"keys_base64":\["[^"]*","[^"]*","\([^"]*\)".*/\1/p')
KEY3=$(echo "$INIT_RESPONSE_CLEAN" | sed -n 's/.*"keys_base64":\["[^"]*","[^"]*","[^"]*","\([^"]*\)".*/\1/p')
KEY4=$(echo "$INIT_RESPONSE_CLEAN" | sed -n 's/.*"keys_base64":\["[^"]*","[^"]*","[^"]*","[^"]*","\([^"]*\)".*/\1/p')

if [ -z "$ROOT_TOKEN" ] || [ -z "$KEY0" ] || [ -z "$KEY1" ] || [ -z "$KEY2" ]; then
  log "ERROR: Missing token or keys from initialization response"
  log "Raw response: $INIT_RESPONSE"
  exit 1
fi

log "Successfully extracted root token and unseal keys"

# Validate key lengths (~44 characters for base64-encoded 32-byte key)
log "Validating unseal key lengths..."
for i in 0 1 2 3 4; do
  eval "key=\$KEY$i"
  key_length=$(echo -n "$key" | wc -c)
  if [ "$key_length" -lt 40 ] || [ "$key_length" -gt 48 ]; then
    log "ERROR: Key $i has unexpected length ($key_length characters, expected ~44)"
    log "Raw init response: $INIT_RESPONSE"
    exit 1
  fi
done
log "All unseal keys validated successfully"

log "Creating Kubernetes secret manifest for unseal keys..."
# TODO : kept for reference
# cat <<EOF > /tmp/vault-unseal-secret.yaml
# apiVersion: v1
# kind: Secret
# metadata:
#   name: $SECRET_NAME
#   namespace: $SECRET_NS
# type: Opaque
# data:
#   vault-unseal-0: $(echo -n "$KEY0" | base64)
#   vault-unseal-1: $(echo -n "$KEY1" | base64)
#   vault-unseal-2: $(echo -n "$KEY2" | base64)
#   vault-unseal-3: $(echo -n "$KEY3" | base64)
#   vault-unseal-4: $(echo -n "$KEY4" | base64)
#   vault-root-token: $(echo -n "$ROOT_TOKEN" | base64)
# EOF

cat <<EOF > /tmp/vault-unseal-secret.json
{
  "apiVersion": "v1",
  "kind": "Secret",
  "metadata": {
    "name": "$SECRET_NAME",
    "namespace": "$SECRET_NS"
  },
  "type": "Opaque",
  "data": {
    "vault-unseal-0": "$(echo -n "$KEY0" | base64)",
    "vault-unseal-1": "$(echo -n "$KEY1" | base64)",
    "vault-unseal-2": "$(echo -n "$KEY2" | base64)",
    "vault-unseal-3": "$(echo -n "$KEY3" | base64)",
    "vault-unseal-4": "$(echo -n "$KEY4" | base64)",
    "vault-root-token": "$(echo -n "$ROOT_TOKEN" | base64)"
  }
}
EOF

if [ ! -f /tmp/vault-unseal-secret.json ]; then
  log "ERROR: Failed to create secret manifest file"
  exit 1
fi

log "Secret manifest created successfully"

log "Applying Vault unseal secret via Kubernetes API..."

SECRET_ENDPOINT="https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT/api/v1/namespaces/$SECRET_NS/secrets/$SECRET_NAME"

max_retries=10
retries=0

while true; do
  log "Attempting to create the secret (attempt $((retries + 1))/$max_retries)..."
  CREATE_RESPONSE=$(curl -sk -w "%%{http_code}" -o /tmp/create_out.json --cacert "$CACERT" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -X POST \
    -d @/tmp/vault-unseal-secret.json \
    "https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT/api/v1/namespaces/$SECRET_NS/secrets")

  if [ "$CREATE_RESPONSE" = "201" ]; then
    log "SUCCESS: Secret created successfully"
    break
  elif [ "$CREATE_RESPONSE" = "409" ]; then
    log "Secret already exists. Attempting to patch..."
    PATCH_RESPONSE=$(curl -sk -w "%%{http_code}" -o /tmp/patch_out.json --cacert "$CACERT" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/merge-patch+json" \
      -X PATCH \
      -d @/tmp/vault-unseal-secret.json \
      "$SECRET_ENDPOINT")

    if [ "$PATCH_RESPONSE" = "200" ]; then
      log "SUCCESS: Secret patched successfully"
      break
    else
      log "WARNING: Patch failed with status $PATCH_RESPONSE. Retrying..."
    fi
  else
    log "WARNING: Create failed with status $CREATE_RESPONSE. Retrying..."
  fi

  retries=$((retries + 1))
  if [ "$retries" -ge "$max_retries" ]; then
    log "ERROR: Failed to apply secret after $max_retries attempts"
    log "Create response: $(cat /tmp/create_out.json 2>/dev/null || echo 'none')"
    log "Patch response: $(cat /tmp/patch_out.json 2>/dev/null || echo 'none')"
    exit 1
  fi

  log "Waiting 5s before retry..."
  sleep 5
done

log "SUCCESS: Vault initialization and secret creation completed"
EOT

    "vault-unsealer.sh" = <<-EOT
#!/bin/sh
set -e

# Kubernetes-friendly logging with timestamps
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Exit gracefully if Vault is already unsealed
check_and_exit_if_unsealed() {
  local health_response="$1"
  if echo "$health_response" | grep -q '"sealed":false'; then
    log "Vault is already unsealed. Exiting gracefully."
    exit 0
  fi
}

# Use Vault service for connection
if [ -n "$VAULT_SERVICE" ] && [ -n "$VAULT_NAMESPACE" ]; then
  VAULT_ADDR="http://$VAULT_SERVICE.$VAULT_NAMESPACE.svc.cluster.local:8200"
else
  # Fallback to internal service name
  VAULT_ADDR="http://${local.module_config.name}.${kubernetes_namespace.this.metadata[0].name}.svc.cluster.local:8200"
fi
log "Using VAULT_ADDR=$VAULT_ADDR"

NAMESPACE=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
CACERT=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
CONSUL_ADDR="${local.module_config.consul_address}"

# Check Vault status - accept both 200 (unsealed) and 503 (sealed) as valid
echo "Checking Vault status at $VAULT_ADDR..."
HEALTH_RESPONSE=$(curl -sk -w "%%{http_code}" -o /tmp/health_response.json "$VAULT_ADDR/v1/sys/health?standbyok=true")
HEALTH_CONTENT=$(cat /tmp/health_response.json)

echo "Vault health check - HTTP status: $HEALTH_RESPONSE"
echo "Health response content: $HEALTH_CONTENT"

# Accept 200 (unsealed), 429 (unsealed but standby), 472 (disaster recovery mode), 473 (performance standby), and 503 (sealed) as valid responses
if [ "$HEALTH_RESPONSE" != "200" ] && [ "$HEALTH_RESPONSE" != "429" ] && [ "$HEALTH_RESPONSE" != "472" ] && [ "$HEALTH_RESPONSE" != "473" ] && [ "$HEALTH_RESPONSE" != "503" ]; then
  echo "Error: Cannot connect to Vault at $VAULT_ADDR. HTTP status: $HEALTH_RESPONSE"
  cat /tmp/health_response.json
  exit 1
fi

# Check if this is a standby node and try to find the active node via Consul
if echo "$HEALTH_CONTENT" | grep -q '"standby":true'; then
  echo "Vault at $VAULT_ADDR is in standby mode. Querying Consul for active node..."
  CONSUL_RESPONSE=$(curl -sk "http://$CONSUL_ADDR/v1/catalog/service/vault" 2>/dev/null || echo "")
  if [ -n "$CONSUL_RESPONSE" ] && echo "$CONSUL_RESPONSE" | grep -q "Address"; then
    # Try to find an active node (this is best effort, we'll continue with current node if not found)
    ACTIVE_ADDR=$(echo "$CONSUL_RESPONSE" | grep -o '"Address":"[^"]*"' | sed 's/"Address":"\(.*\)"/\1/' | head -n 1)
    ACTIVE_PORT=$(echo "$CONSUL_RESPONSE" | grep -o '"ServicePort":[0-9]*' | sed 's/"ServicePort":\([0-9]*\)/\1/' | head -n 1)
    if [ -n "$ACTIVE_ADDR" ] && [ -n "$ACTIVE_PORT" ]; then
      NEW_VAULT_ADDR="http://$ACTIVE_ADDR:$ACTIVE_PORT"
      echo "Testing connection to potential active node: $NEW_VAULT_ADDR"
      TEST_RESPONSE=$(curl -sk -w "%%{http_code}" -o /tmp/test_health.json "$NEW_VAULT_ADDR/v1/sys/health?standbyok=true" 2>/dev/null || echo "000")
      if [ "$TEST_RESPONSE" = "200" ] || [ "$TEST_RESPONSE" = "503" ]; then
        VAULT_ADDR="$NEW_VAULT_ADDR"
        echo "Updated VAULT_ADDR to: $VAULT_ADDR"
        HEALTH_CONTENT=$(cat /tmp/test_health.json)
      else
        echo "Could not connect to $NEW_VAULT_ADDR (status: $TEST_RESPONSE), continuing with current node"
      fi
    else
      echo "Could not parse active node from Consul response, continuing with current node"
    fi
  else
    echo "Could not query Consul or parse response, continuing with current node"
  fi
fi

echo "Final VAULT_ADDR: $VAULT_ADDR"

# Check if Vault is initialized and sealed
if echo "$HEALTH_CONTENT" | grep -q '"initialized":false'; then
  echo "Error: Vault is not initialized. Cannot proceed with unseal."
  exit 1
elif echo "$HEALTH_CONTENT" | grep -q '"sealed":false'; then
  echo "Vault is already unsealed. No action needed."
  exit 0
elif ! echo "$HEALTH_CONTENT" | grep -q '"sealed":true'; then
  echo "Error: Cannot determine Vault seal status from: $HEALTH_CONTENT"
  exit 1
fi

echo "Vault is sealed and ready for unsealing."

echo "Checking if secret vault-unseal-keys exists..."
SECRET_ENDPOINT="https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT/api/v1/namespaces/$NAMESPACE/secrets/vault-unseal-keys"
SECRET_CHECK=$(curl -sk -w "%%{http_code}" -o /tmp/secret_check.json --cacert "$CACERT" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/json" \
  "$SECRET_ENDPOINT")

if [ "$SECRET_CHECK" -ne 200 ]; then
  echo "Error: Secret vault-unseal-keys not found or inaccessible. HTTP status: $SECRET_CHECK"
  cat /tmp/secret_check.json
  exit 1
fi

echo "Fetching unseal keys..."
SECRET_RESPONSE=$(curl -sk --cacert "$CACERT" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/json" \
  "$SECRET_ENDPOINT")

if [ -z "$SECRET_RESPONSE" ]; then
  echo "Error: Failed to fetch secret vault-unseal-keys"
  exit 1
fi

echo "$SECRET_RESPONSE" > /tmp/vault-unseal-secret.json

get_key() {
  echo "$SECRET_RESPONSE" | grep "\"$1\"" | sed -n 's/.*"'$1'" *: *"\([^"]*\)".*/\1/p' | base64 -d
}

echo "Starting unseal process..."
for i in 0 1 2; do
  key=$(get_key vault-unseal-$i)
  if [ -z "$key" ]; then
    echo "Error: Failed to retrieve key vault-unseal-$i"
    exit 1
  fi

  # Validate the key length (should be ~44 characters for base64-encoded 32-byte key)
  key_length=$(echo -n "$key" | wc -c)
  if [ "$key_length" -lt 40 ] || [ "$key_length" -gt 48 ]; then
    echo "Error: Key vault-unseal-$i has unexpected length ($key_length characters, expected ~44)."
    exit 1
  fi

  echo "Unsealing with key $i (length: $key_length bytes)..."
  UNSEAL_RESPONSE=$(curl -sk -w "%%{http_code}" -o /tmp/unseal_response.json \
    --request PUT \
    --header "Content-Type: application/json" \
    --data "{\"key\":\"$key\"}" \
    "$VAULT_ADDR/v1/sys/unseal")

  echo "Unseal attempt $i - HTTP status: $UNSEAL_RESPONSE"

  if [ "$UNSEAL_RESPONSE" -ne 200 ]; then
    echo "Error: Unseal attempt with key $i failed. HTTP status: $UNSEAL_RESPONSE"
    cat /tmp/unseal_response.json
    exit 1
  fi

  UNSEAL_CONTENT=$(cat /tmp/unseal_response.json)
  echo "Unseal response for key $i: $UNSEAL_CONTENT"

  # Check if unsealing is complete
  if echo "$UNSEAL_CONTENT" | grep -q '"sealed":false'; then
    echo "Vault successfully unsealed after $((i+1)) keys!"
    break
  elif echo "$UNSEAL_CONTENT" | grep -q '"errors"'; then
    echo "Error: Unseal attempt with key $i failed due to invalid key"
    exit 1
  else
    echo "Unseal key $i accepted, continuing..."
  fi

  sleep 2
done

# Final verification
echo "Verifying Vault is unsealed..."
FINAL_HEALTH=$(curl -sk -w "%%{http_code}" -o /tmp/final_health.json "$VAULT_ADDR/v1/sys/health?standbyok=true")
FINAL_CONTENT=$(cat /tmp/final_health.json)

if [ "$FINAL_HEALTH" = "200" ] && echo "$FINAL_CONTENT" | grep -q '"sealed":false'; then
  echo "Vault successfully unsealed and ready!"
elif [ "$FINAL_HEALTH" = "429" ] && echo "$FINAL_CONTENT" | grep -q '"sealed":false'; then
  echo "Vault successfully unsealed (in standby mode)!"
else
  echo "Warning: Vault status unclear after unseal. Final status: $FINAL_HEALTH"
  echo "Final response: $FINAL_CONTENT"
fi
EOT
  }
}
