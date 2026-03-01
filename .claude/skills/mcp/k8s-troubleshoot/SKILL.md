---
description: Analyze Kubernetes issues and identify root causes using MCP
---

# Kubernetes Troubleshooting

Analyze Kubernetes deployment issues and identify root causes using the kubectl MCP server.

**IMPORTANT**: This skill is READ-ONLY. It never modifies Kubernetes objects. Use the k8s-deploy skill for deployment changes.

## Purpose

Systematically analyze Kubernetes deployment problems by examining pod status, logs, events, and cluster state. Provides structured diagnosis and root cause identification without making any changes to the cluster.

**Category**: DevOps & Infrastructure

## Inputs

### Required
- **Issue description**: What problem are you experiencing? (e.g., "Pods not starting", "CrashLoopBackOff", "High memory usage")

### Optional
- **Deployment name**: Specific deployment to troubleshoot
- **Namespace**: Kubernetes namespace (default: `default`)
- **Pod name**: Specific pod to investigate
- **Component**: Which part of the system (deployment, service, ingress, configmap, etc.)

## System Context

Before starting:
- Read `memory.md` for recent deployment history and known issues
- Check `knowledge-base.md` for previous K8s troubleshooting patterns
- Review any incident logs for recent K8s-related problems

## Process

### Step 1: Initial Assessment

Gather basic information about the issue:
- When did the problem start?
- What changed recently? (new deployment, config change, cluster update)
- Is it affecting all pods or specific ones?
- What are the symptoms? (crashes, hangs, errors, slow response)

### Step 2: Check Cluster Health

Check overall cluster status:
- `kubectl_get nodes` — Are nodes Ready?
- `kubectl_get namespaces` — Does the namespace exist?
- `kubectl_get pods --all-namespaces` — Cluster-wide pod status

### Step 3: Analyze Deployment State

For the affected deployment:
- `kubectl_get deployments` — Is the deployment rolling out?
- `kubectl_describe deployment [name]` — Check deployment status and conditions
- `kubectl_rollout history deployment/[name]` — Recent rollout history

### Step 4: Investigate Pod Issues

For problematic pods:
- `kubectl_get pods` — List all pods with status
- `kubectl_describe pod [name]` — Detailed pod information
- `kubectl_logs [pod-name]` — Container logs
- `kubectl_logs [pod-name] --previous` — Previous container logs if restarted

### Step 5: Check Resources and Limits

Analyze resource usage:
- `kubectl_describe pod [name]` — Check resource requests and limits
- Look for OOMKilled events
- Check resource quotas in the namespace

### Step 6: Review Events

Check recent events for clues:
- `kubectl_get events --sort-by='.lastTimestamp'` — Recent cluster events
- Filter by namespace or resource type
- Look for Warning and Error events

### Step 7: Verify Configuration

Check related resources:
- `kubectl_get services` — Are services pointing to correct pods?
- `kubectl_get configmaps` — Are configmaps mounted correctly?
- `kubectl_get secrets` — Do secrets exist and are valid?
- `kubectl_get ingress` — Is ingress configured properly?

### Step 8: Network Connectivity

If network issues are suspected:
- Check service endpoints: `kubectl_get endpoints`
- Test pod-to-pod communication
- Verify network policies
- Check DNS resolution: `kubectl_get services` for CoreDNS

## Output Format

```markdown
# Kubernetes Troubleshooting Report: [Issue]

## Executive Summary
- **Issue**: [problem description]
- **Severity**: [critical/high/medium/low]
- **Affected Resources**: [deployments, pods, services]
- **Root Cause**: [identified root cause]
- **Status**: [diagnosing/resolved/unresolved]

## Issue Details
[description of what was observed]

## Diagnosis Steps Taken

### Cluster Health
- **Nodes**: [status and details]
- **Namespace**: [status and details]
- **Resource Quotas**: [if applicable]

### Deployment Analysis
- **Deployment Status**: [current state]
- **Replica Count**: [desired vs actual]
- **Rollout History**: [recent changes]

### Pod Investigation
- **Pod Status**: [current states]
- **Restarts**: [restart count and trends]
- **Events**: [recent pod events]

### Log Analysis
- **Application Logs**:
  ```
  [relevant log excerpts]
  ```
- **System Events**:
  ```
  [relevant system events]
  ```

## Root Cause Analysis

**Identified Issue**:
- **Category**: [resource/configuration/network/application]
- **Details**: [specific problem identified]
- **Evidence**: [supporting logs, events, or metrics]
- **Contributing Factors**: [what led to this issue]

## Analysis Findings

**What Was Observed**:
- [Cluster state observations]
- [Resource status and constraints]
- [Configuration issues detected]
- [Network or connectivity problems]

**Key Evidence**:
- [Log excerpts showing the problem]
- [Event messages indicating failure causes]
- [Resource limits or quota issues]
- [Configuration mismatches]

**Suggested Investigation Areas**:
- [Areas that may need further examination]
- [Related components to check]
- [Configuration files to review]

## Prevention Considerations
[Observations on how to avoid similar issues in the future - for planning purposes only]
```

## Common Issues and Root Cause Indicators

### Image Pull Errors
**Symptoms**: `ErrImagePull`, `ImagePullBackOff`

**Diagnosis**:
```
kubectl_describe pod [pod-name]
kubectl_logs [pod-name]
```

**Root Cause Indicators**:
- Wrong image name or tag — check image reference in pod spec
- Private registry authentication issues — look for "unauthorized" or "denied" in events
- Registry not accessible — network connectivity or DNS issues
- Image doesn't exist for requested architecture — platform mismatch (amd64/arm64)

**Evidence to Gather**:
- Image pull secrets status
- Registry accessibility from cluster
- Image manifest availability

### CrashLoopBackOff
**Symptoms**: Pod restarts repeatedly

**Diagnosis**:
```
kubectl_logs [pod-name]
kubectl_logs [pod-name] --previous
kubectl_describe pod [pod-name]
```

**Root Cause Indicators**:
- Application crashes on startup — check application logs for stack traces
- Missing environment variables — look for "missing key" or "not found" errors
- Incorrect configuration — ConfigMap/Secret mount failures
- Missing dependencies or volumes — volume mount errors in events
- Liveness probe failing too aggressively — probe timeout before startup

**Evidence to Gather**:
- Application startup logs
- Environment variable listings
- Volume mount status
- Probe configuration and timing

### Pending Pods
**Symptoms**: Pods stay in Pending state

**Diagnosis**:
```
kubectl_describe pod [pod-name]
kubectl_get events
```

**Root Cause Indicators**:
- Insufficient cluster resources — check node capacity vs resource requests
- Node selectors/taints/tolerations mismatch — pod can't be scheduled
- PersistentVolumeClaims not bound — storage unavailable
- Image pull backoff — container image can't be fetched
- Scheduler constraints — affinity/anti-affinity rules blocking

**Evidence to Gather**:
- Node resource availability
- Pod scheduling constraints
- PVC binding status
- Taint/toleration configurations

### Resource Exhaustion
**Symptoms**: OOMKilled, CPU throttling

**Diagnosis**:
```
kubectl_describe pod [pod-name]
kubectl_top_nodes
kubectl_top_pods
```

**Root Cause Indicators**:
- Memory limits exceeded — OOMKilled events
- CPU throttling — usage at or near limits
- No limits set — resource starvation of other pods
- Requests too high — can't schedule on available nodes
- Requests too low — QoS class affects scheduling priority

**Evidence to Gather**:
- Resource requests vs actual usage
- Limit configurations
- Node capacity utilization
- OOM events and timestamps

### Service Discovery Issues
**Symptoms**: Can't reach service, DNS failures

**Diagnosis**:
```
kubectl_get endpoints [service-name]
kubectl_describe service [service-name]
kubectl_exec [pod] -- nslookup [service]
```

**Root Cause Indicators**:
- Wrong selector labels — no endpoints selected
- Wrong port configuration — port mismatch
- Service not in same namespace — namespace isolation
- CoreDNS issues — DNS resolution failures
- Network policies blocking traffic — policy denies access

**Evidence to Gather**:
- Service endpoint status
- Pod label matches
- Port configurations
- Network policy rules

## Quality Validation

- [ ] Issue description is clear and specific
- [ ] Relevant logs and events have been captured
- [ ] Multiple diagnostic steps have been attempted
- [ ] Root cause has been identified or best effort made
- [ ] Evidence is documented with specific references
- [ ] Analysis findings are objective and evidence-based
- [ ] No modification recommendations are made (use k8s-deploy skill for changes)
- [ ] Report is clear and actionable for decision-makers

## Pro Tips

1. **Start broad, then narrow**: Cluster → Namespace → Deployment → Pod → Container
2. **Events are your friend**: `kubectl get events` often shows the root cause
3. **Describe everything**: `kubectl describe` reveals configuration issues without modifying state
4. **Check previous logs**: `--previous` flag shows logs from before container restart
5. **Resource quotas**: Can prevent pods from scheduling; check `kubectl describe namespace`
6. **Compare with working pods**: `kubectl get pods -o wide` can show node distribution
7. **Use labels effectively**: `-l app=xyz` to filter resources
8. **YAML vs JSON**: Sometimes `kubectl get -o yaml` is more readable than describe output
9. **Document findings**: Provide evidence-based analysis for informed decision-making
10. **Stay read-only**: This skill identifies problems — use k8s-deploy skill for making changes
