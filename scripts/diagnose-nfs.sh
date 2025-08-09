#!/bin/bash

# NFS CSI Connectivity Diagnostic Script
echo "🔍 NFS CSI Connectivity Diagnostics"
echo "====================================="

# Check if NFS server and path are configured
echo ""
echo "📋 Current Configuration:"
echo "------------------------"
if [ -f terraform.tfvars ]; then
    echo "NFS Server: $(grep nfs_server terraform.tfvars || echo 'Not configured')"
    echo "NFS Path: $(grep nfs_path terraform.tfvars || echo 'Not configured')"
else
    echo "❌ terraform.tfvars not found"
fi

# Read NFS configuration from terraform.tfvars
NFS_SERVER=$(grep '^nfs_server' terraform.tfvars 2>/dev/null | cut -d'=' -f2 | tr -d ' "')
NFS_PATH=$(grep '^nfs_path' terraform.tfvars 2>/dev/null | cut -d'=' -f2 | tr -d ' "')

if [ -z "$NFS_SERVER" ]; then
    echo "❌ NFS_SERVER not found in terraform.tfvars"
    echo "   Please add: nfs_server = \"YOUR_NFS_SERVER_IP\""
    exit 1
fi

if [ -z "$NFS_PATH" ]; then
    echo "❌ NFS_PATH not found in terraform.tfvars"
    echo "   Please add: nfs_path = \"/path/to/nfs/export\""
    exit 1
fi

echo ""
echo "🌐 Network Connectivity Tests:"
echo "-----------------------------"

# Test basic connectivity
echo -n "Ping NFS Server ($NFS_SERVER): "
if ping -c 1 -W 2 "$NFS_SERVER" >/dev/null 2>&1; then
    echo "✅ SUCCESS"
else
    echo "❌ FAILED - Cannot reach NFS server"
fi

# Test NFS port connectivity
echo -n "NFS Port 2049: "
if timeout 5 bash -c "</dev/tcp/$NFS_SERVER/2049" 2>/dev/null; then
    echo "✅ OPEN"
else
    echo "❌ CLOSED/FILTERED"
fi

# Test RPC port connectivity
echo -n "RPC Port 111: "
if timeout 5 bash -c "</dev/tcp/$NFS_SERVER/111" 2>/dev/null; then
    echo "✅ OPEN"
else
    echo "❌ CLOSED/FILTERED"
fi

echo ""
echo "🗂️  NFS Export Tests:"
echo "--------------------"

# Test NFS exports (if showmount is available)
echo -n "NFS Exports: "
if command -v showmount >/dev/null 2>&1; then
    if timeout 10 showmount -e "$NFS_SERVER" >/dev/null 2>&1; then
        echo "✅ ACCESSIBLE"
        echo "Available exports:"
        timeout 10 showmount -e "$NFS_SERVER" 2>/dev/null | grep -v "Export list"
    else
        echo "❌ TIMEOUT/FAILED"
    fi
else
    echo "⚠️  showmount not available (install nfs-utils)"
fi

echo ""
echo "🔧 DNS Resolution Tests:"
echo "-----------------------"

# Test DNS resolution
echo -n "DNS Resolution: "
if nslookup "$NFS_SERVER" >/dev/null 2>&1; then
    echo "✅ SUCCESS"
    nslookup "$NFS_SERVER" | grep -A2 "Name:"
else
    echo "❌ FAILED"
    echo "   Try using IP address instead of hostname"
fi

echo ""
echo "🐳 Kubernetes Cluster Tests:"
echo "----------------------------"

# Check if NFS CSI is deployed
echo -n "NFS CSI Namespace: "
if kubectl get namespace nfs-csi-stack >/dev/null 2>&1; then
    echo "✅ EXISTS"
else
    echo "❌ NOT FOUND"
fi

echo -n "NFS CSI Pods: "
POD_COUNT=$(kubectl get pods -n nfs-csi-stack --no-headers 2>/dev/null | wc -l)
if [ "$POD_COUNT" -gt 0 ]; then
    echo "✅ $POD_COUNT pods running"
    kubectl get pods -n nfs-csi-stack
else
    echo "❌ NO PODS RUNNING"
fi

# Check storage classes
echo ""
echo "Storage Classes:"
kubectl get storageclass | grep nfs || echo "No NFS storage classes found"

echo ""
echo "🧪 Test NFS Mount from Node:"
echo "---------------------------"
echo "Run this on a cluster node to test manual mounting:"
echo ""
echo "# Install NFS client utilities (if not present)"
echo "sudo apt-get update && sudo apt-get install -y nfs-common"
echo "# or on RHEL/CentOS:"
echo "sudo yum install -y nfs-utils"
echo ""
echo "# Test manual mount"
echo "sudo mkdir -p /tmp/nfs-test"
echo "sudo mount -t nfs -o vers=4,timeo=30 $NFS_SERVER:$NFS_PATH /tmp/nfs-test"
echo "ls -la /tmp/nfs-test"
echo "sudo umount /tmp/nfs-test"

echo ""
echo "🔧 Recommended Fixes:"
echo "--------------------"
echo "1. If ping fails: Check network connectivity and routing"
echo "2. If ports are closed: Configure firewall on NFS server"
echo "3. If exports fail: Check NFS server configuration and /etc/exports"
echo "4. If DNS fails: Use IP address instead of hostname"
echo "5. Try different NFS versions (vers=3 instead of vers=4)"

echo ""
echo "📝 Common NFS Server Fixes:"
echo "--------------------------"
echo "# On NFS Server, edit /etc/exports:"
echo "$NFS_PATH *(rw,sync,no_subtree_check,no_root_squash)"
echo ""
echo "# Restart NFS services:"
echo "sudo systemctl restart nfs-server"
echo "sudo systemctl restart rpcbind"
echo "sudo exportfs -ra"
echo ""
echo "# Open firewall ports:"
echo "sudo ufw allow 111"
echo "sudo ufw allow 2049"
echo "# or for iptables:"
echo "sudo iptables -A INPUT -p tcp --dport 111 -j ACCEPT"
echo "sudo iptables -A INPUT -p tcp --dport 2049 -j ACCEPT"
