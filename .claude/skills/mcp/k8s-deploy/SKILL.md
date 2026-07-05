---
description: Deploy application to Kubernetes using MCP
---

# Kubernetes Deployment

Deploy applications to Kubernetes using the kubectl MCP server.

## Purpose

Automate Kubernetes deployments with validation and rollback capabilities using the kubectl MCP server.

**Category**: DevOps & Infrastructure

## Inputs

### Required
- **Deployment name**: Name for the Kubernetes deployment
- **Container image**: Docker image to deploy (e.g., `nginx:latest`)

### Optional
- **Replicas**: Number of pod replicas (default: 1)
- **Port**: Container port to expose (default: 80)
- **Namespace**: Kubernetes namespace (default: `default`)
- **Environment variables**: KEY=value pairs for container env

## System Context

Before starting:
- Read `memory.md` for current deployment context
- Check `.mcp.json` to verify kubernetes MCP is enabled
- Review any existing deployment manifests in the project

## Process

### Step 1: Pre-deployment Check

- Check current deployment status: `kubectl_get deployments`
- Check existing pods: `kubectl_get pods`
- Verify namespace exists: `kubectl_get namespaces`

### Step 2: Create Deployment Manifest

Generate Kubernetes deployment YAML:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: [deployment-name]
  namespace: [namespace]
spec:
  replicas: [replicas]
  selector:
    matchLabels:
      app: [deployment-name]
  template:
    metadata:
      labels:
        app: [deployment-name]
    spec:
      containers:
      - name: [deployment-name]
        image: [container-image]
        ports:
        - containerPort: [port]
        env: [environment-variables]
```

### Step 3: Deploy

- Apply manifest: `kubectl_apply` with the deployment YAML
- Watch rollout status: `kubectl_rollout` status

### Step 4: Validation

- Check deployment status: `kubectl_describe deployment [name]`
- Check pod status: `kubectl_get pods -l app=[name]`
- Verify pod readiness: `kubectl_get pods` for READY status

### Step 5: Rollback on Failure

If deployment fails:
- Check rollout history: `kubectl_rollout history deployment/[name]`
- Rollback if needed: `kubectl_rollout undo deployment/[name]`

## Output Format

```markdown
# Deployment Summary: [deployment-name]

## Status
- **Status**: [success/failed/partial]
- **Replicas**: [desired] / [ready]
- **Pods**: [list of pod names and statuses]

## Details
[deployment details from kubectl_describe]

## Events
[recent events from the deployment]

## Next Steps
[recommendations or follow-up actions]
```

## Quality Validation

- [ ] Deployment manifest is valid Kubernetes YAML
- [ ] Image name is specified and accessible
- [ ] Namespace exists (or will be created)
- [ ] Replicas count is reasonable
- [ ] Resource limits are specified if needed
- [ ] Health checks are configured if applicable

## Troubleshooting

**Common Issues:**
- ImagePullBackOff: Check image name and registry access
- CrashLoopBackOff: Check application logs for errors
- Pending pods: Check resource limits or node availability
- Failed scheduling: Check taints/tolerations or resource quotas
