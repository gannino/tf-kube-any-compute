#!/bin/bash
set -euo pipefail

# Fix NFS CSI deployment issue
# This script addresses the "access denied by server" NFS mount error

echo "🔧 tf-kube-any-compute NFS Issue Fix"
echo "===================================="

# Check if we're in the right directory
if [[ ! -f "terraform.tfvars" ]]; then
    echo "❌ Error: terraform.tfvars not found. Run this script from the tf-kube-any-compute directory."
    exit 1
fi

echo "📋 Checking current NFS configuration..."

# Extract NFS server details from terraform.tfvars
NFS_SERVER=$(grep "nfs_server_address" terraform.tfvars | cut -d'"' -f2)
NFS_PATH=$(grep "nfs_server_path" terraform.tfvars | cut -d'"' -f2)

echo "   NFS Server: $NFS_SERVER"
echo "   NFS Path: $NFS_PATH"

# Check if NFS CSI is currently failing
echo "🔍 Checking NFS CSI pod status..."
if kubectl get pods -n prod-nfs-csi-system 2>/dev/null | grep -q "ContainerCreating\|Error\|CrashLoopBackOff"; then
    echo "❌ NFS CSI pod is failing"

    # Show the specific error
    echo "📝 Error details:"
    kubectl describe pods -n prod-nfs-csi-system | grep -A 5 -B 5 "access denied\|mount failed" || true

    echo ""
    echo "🛠️  Available fix options:"
    echo ""
    echo "Option 1: Fix NFS Server (Recommended)"
    echo "--------------------------------------"
    echo "On your NFS server ($NFS_SERVER), run:"
    echo ""
    echo "  sudo nano /etc/exports"
    echo "  # Add or modify:"
    echo "  $NFS_PATH *(rw,sync,no_subtree_check,no_root_squash,insecure)"
    echo ""
    echo "  sudo exportfs -ra"
    echo "  sudo systemctl restart nfs-kernel-server"
    echo ""

    echo "Option 2: Switch to HostPath Storage (Quick Fix)"
    echo "-----------------------------------------------"
    read -p "Switch to HostPath storage temporarily? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🔄 Switching to HostPath storage..."

        # Backup current config
        cp terraform.tfvars terraform.tfvars.backup.$(date +%Y%m%d_%H%M%S)

        # Update storage configuration
        sed -i.bak 's/use_nfs_storage      = true/use_nfs_storage      = false  # Temporarily disabled - NFS server access denied/' terraform.tfvars

        # Update service overrides to use hostpath
        sed -i.bak 's/nfs-csi-safe/hostpath/g' terraform.tfvars
        sed -i.bak 's/nfs-csi-fast/hostpath/g' terraform.tfvars

        echo "✅ Configuration updated to use HostPath storage"
        echo "📁 Backup saved as: terraform.tfvars.backup.*"

        # Clean up failed NFS deployment
        echo "🧹 Cleaning up failed NFS deployment..."
        helm uninstall prod-nfs-csi -n prod-nfs-csi-system 2>/dev/null || true
        kubectl delete namespace prod-nfs-csi-system 2>/dev/null || true

        echo "🚀 Ready to redeploy with HostPath storage:"
        echo "   make plan"
        echo "   make apply"

    else
        echo "ℹ️  No changes made. Fix NFS server configuration and retry deployment."
    fi

else
    echo "✅ NFS CSI appears to be working correctly"
fi

echo ""
echo "📚 For complete setup instructions, see:"
echo "   docs/guides/MICROK8S-RASPBERRY-PI-GUIDE.md"
echo ""
echo "🔧 To test NFS connectivity manually:"
echo "   showmount -e $NFS_SERVER"
echo "   sudo mount -t nfs $NFS_SERVER:$NFS_PATH /mnt/test"
