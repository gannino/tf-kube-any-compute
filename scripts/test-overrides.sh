#!/bin/bash

echo "=== Testing Service Overrides ==="
echo ""

echo "1. Traefik storage class override:"
terraform console <<'EOF'
local.service_configs.traefik.storage_class
EOF

echo ""
echo "2. Consul server replicas override:"
terraform console <<'EOF'
local.service_configs.consul.server_replicas
EOF

echo ""
echo "3. Prometheus storage class override:"
terraform console <<'EOF'
local.service_configs.prometheus.storage_class
EOF

echo ""
echo "4. Node-RED palette packages override:"
terraform console <<'EOF'
local.service_configs.node_red.palette_packages
EOF

echo ""
echo "=== Testing Middleware Overrides ==="
echo ""

echo "5. Middleware enabled status:"
terraform console <<'EOF'
var.middleware_overrides.enabled
EOF

echo ""
echo "6. Traefik middleware config (basic_auth):"
terraform console <<'EOF'
try(var.service_overrides.traefik.middleware_config.basic_auth.enabled, "REMOVED - Using middleware_overrides instead")
EOF

echo ""
echo "7. Middleware from terraform.tfvars:"
terraform console <<'EOF'
var.service_overrides.traefik.middleware_config
EOF

echo ""
echo "8. Service middlewares for prometheus:"
terraform console <<'EOF'
local.service_middlewares_with_custom.prometheus
EOF

echo ""
echo "9. Service middlewares for traefik:"
terraform console <<'EOF'
local.service_middlewares_with_custom.traefik
EOF

echo ""
echo "=== Verification Complete ==="
