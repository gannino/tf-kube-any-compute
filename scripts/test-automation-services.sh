#!/bin/bash
# Test automation services deployment

set -e

echo "🧪 Testing Automation Services Deployment"
echo "=========================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if services are enabled
check_service() {
    local service=$1
    local namespace=$2

    echo -e "\n${YELLOW}Checking ${service}...${NC}"

    # Check deployment
    if kubectl get deployment -n "$namespace" 2>/dev/null | grep -q "$service"; then
        echo -e "${GREEN}✓ Deployment found${NC}"

        # Check pod status
        local ready=$(kubectl get deployment -n "$namespace" -o jsonpath="{.items[?(@.metadata.name=='$service')].status.readyReplicas}")
        local desired=$(kubectl get deployment -n "$namespace" -o jsonpath="{.items[?(@.metadata.name=='$service')].spec.replicas}")

        if [ "$ready" == "$desired" ]; then
            echo -e "${GREEN}✓ Pod ready ($ready/$desired)${NC}"
        else
            echo -e "${YELLOW}⚠ Pod not ready yet ($ready/$desired)${NC}"
        fi

        # Check service
        if kubectl get svc -n "$namespace" "$service" 2>/dev/null >/dev/null; then
            echo -e "${GREEN}✓ Service found${NC}"
        else
            echo -e "${RED}✗ Service not found${NC}"
        fi

        # Check PVC
        if kubectl get pvc -n "$namespace" 2>/dev/null | grep -q "$service"; then
            echo -e "${GREEN}✓ PVC found${NC}"
        else
            echo -e "${YELLOW}⚠ No PVC found (persistence may be disabled)${NC}"
        fi

    else
        echo -e "${YELLOW}⚠ Service not deployed${NC}"
    fi
}

# Test each service
check_service "prod-home-assistant" "prod-home-assistant-system"
check_service "prod-openhab" "prod-openhab-system"
check_service "prod-homebridge" "prod-homebridge-system"

echo -e "\n${GREEN}=========================================="
echo "Test complete!"
echo -e "==========================================${NC}"
