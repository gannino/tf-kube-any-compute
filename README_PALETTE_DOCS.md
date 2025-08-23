#### Node-RED Palette Installation

**tf-kube-any-compute** automatically installs Node-RED palette packages through a separate Kubernetes Job:

- **📦 Package Support**: Both npm registry packages and git repositories
- **🔄 Non-blocking**: Installation runs separately from Node-RED deployment
- **🎯 Smart Detection**: Automatically handles npm vs git package installation
- **📊 Progress Tracking**: Detailed logging with timestamps and status
- **🔄 Update Handling**: Checks for updates on existing packages
- **💾 Persistent**: Uses ReadWriteMany PVC for concurrent access

**Supported Package Formats:**
```bash
# NPM registry packages
"node-red-dashboard"
"node-red-contrib-home-assistant-websocket"

# GitHub repositories
"https://github.com/user/repo.git"
"git+https://github.com/user/repo.git"
"git+ssh://git@github.com/user/repo.git"
```

**Installation Process:**
1. Node-RED deploys immediately (no waiting)
2. Separate job installs packages in background
3. Restart Node-RED pod to load new packages: `kubectl rollout restart deployment/prod-node-red -n prod-node-red-system`

> ✅ **n8n Status**: Now available with native Terraform implementation! Provides enterprise-grade security, resource management, and full feature parity without Helm dependencies.
