# microk8s + Tailscale: setup, recovery, and failure-mode reference

Scripts and field notes for running a microk8s cluster where every node
communicates over [Tailscale](https://tailscale.com). This setup works, but
the default install procedure produces a cluster that **flaps** — nodes
silently go `NotReady` and only the control-plane node stays alive.

This folder contains the corrected install script, a recovery script for
nodes already deployed the broken way, and a reference of every failure
mode observed in the field so you don't have to re-derive them.

## Files

| File | Purpose |
|---|---|
| [setup-microk8s-tailscale-node.sh](setup-microk8s-tailscale-node.sh) | Install Tailscale + microk8s on a **fresh** node, correctly configured. Two modes: `init` (control plane) and `join` (worker). |
| [recover-microk8s-tailscale-node.sh](recover-microk8s-tailscale-node.sh) | Repair a **NotReady** node already deployed. Fixes `--node-ip`, regenerates the kubelet serving cert, restarts services, checks Tailscale/MTU. Idempotent. |
| [README.md](README.md) | This document — failure-mode reference + usage. |

## The core problem

A naive install (Tailscale up → microk8s install → add-node) leaves the
kubelet pinned to the node's **LAN IP**. The kubelet generates its serving
certificate with LAN IPs in the SAN list. Meanwhile, the cluster registers
the node by its **Tailscale IP** (100.64.0.0/10). The result:

```
kubelet serving cert SANs: 192.168.x.x, 172.17.0.1, hostname
cluster node IP:           100.104.141.106   ← Tailscale

→ API server tries kubectl logs / exec / metrics at 100.104.141.106:10250
→ x509: certificate is valid for 192.168.x.x, ..., not 100.104.141.106
→ TLS verification fails → API server marks the node unreachable
```

Heartbeats (kubelet → API server, client cert) keep working for a while, so
the failure is intermittent and confusing.

## Design principle: IP-first

This cluster operates on **Tailscale IPs, not names**. No dependency on
MagicDNS resolution. Everything that can use an IP, uses an IP:

- `--node-ip` pinned to the Tailscale IP (node advertises an IP, not a name)
- Kubelet serving cert carries **IP SANs** (the API server connects by IP and
  validates the cert against IP SANs — no DNS lookup involved)
- API server configured `--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname`
  so it reaches kubelets by IP before falling back to hostname
- In the rare case a name is needed in a cert, use the **full MagicDNS name**
  (`node.bearded-caiman.ts.net`), not the short hostname — short names only
  resolve when the client's DNS search domain includes the tailnet, which is
  not guaranteed. IPs remain primary; names are fallback insurance.

## Failure modes observed

Every issue we have actually seen, with symptom → root cause → diagnostic.

### 1. Kubelet serving cert lacks Tailscale IP SAN

- **Symptom**: `kubectl logs <pod>` fails with
  `x509: cannot validate certificate for 100.x.x.x because it doesn't contain any IP SANs`
  (or the older `certificate is valid for 192.168.x.x, not 100.x.x.x` form).
  Node can still show `Ready` — heartbeats work; only API→kubelet calls break.
- **Root cause**: microk8s's kubelet auto-generates its serving cert on first
  start / restart, but that auto-generation **only stamps the hostname as SAN** —
  it does not enumerate interface IPs. So `--node-ip=<tailscale-ip>` plus
  "delete the cert + restart kubelet" produces a fresh DNS-only cert every
  time. The Tailscale IP never lands in the SAN. (Confirmed 2026-07-12 on
  raspi3: regenerated cert had only `DNS:raspberrypi3`, zero IPs.)
- **Diagnostic**:
  ```bash
  # On the node — does the cert carry the Tailscale IP?
  openssl x509 -in /var/snap/microk8s/current/certs/kubelet.crt -noout -ext subjectAltName
  # From operator — does the API server accept the cert?
  kubectl get --raw='/api/v1/nodes/<node>/proxy/healthz'
  ```
- **Fix**: generate the serving cert **explicitly** with IP SANs, signed by
  microk8s's CA (`/var/snap/microk8s/current/certs/ca.{crt,key}`). Do NOT rely
  on the kubelet's auto-regeneration. Both scripts in this folder do this —
  the SAN includes `IP:<tailscale>`, `IP:<lan>`, `IP:127.0.0.1`, plus
  `DNS:localhost` and `DNS:<full-magicdns-name>` as fallback.

### 2. Single control plane + Tailscale-only workers

- **Symptom**: exactly one node stays `Ready` (the one hosting the API server);
  all others flap to `NotReady` in waves. `etcd-0` is the only etcd member.
- **Root cause**: every worker's heartbeat crosses Tailscale. The control-plane
  node heartbeats to itself via loopback, so it never drops. Any Tailscale
  hiccup on a worker = that worker dies.
- **Diagnostic**:
  ```bash
  kubectl get endpoints kubernetes      # single IP = single control plane
  kubectl get componentstatuses         # etcd-0 only = no HA
  ```
- **Fix**: run a 3-node HA control plane (`microk8s add-node` on 3 nodes,
  dqlite replicates). Tolerates a node or VPN blip.

### 3. Tailscale ACLs block Kubernetes ports

- **Symptom**: recovery script's connectivity test warns
  `API server port 16443 NOT reachable`. Node heartbeats never land.
- **Root cause**: Tailscale default ACL is "allow all", but any custom ACL
  in the admin console locks traffic to explicit rules. The Kubernetes
  ports get dropped.
- **Ports that must be allowed between cluster nodes**:
  | Port | Purpose |
  |---|---|
  | `tcp:16443` | microk8s API server (note: non-standard, not 6443) |
  | `tcp:10250` | kubelet serving (API server → kubelet) |
  | `tcp:25000` | microk8s cluster join (add-node) |
  | `tcp:19001-19010` | dqlite HA datastore (if 3-node HA) |
- **Fix**: edit the Tailscale ACL in the admin console. Scripts cannot fix this.

### 4. MTU fragmentation (double encapsulation)

- **Symptom**: heartbeats and small comms work, but large payloads silently
  fail — cert rotations time out, big ConfigMaps never apply, `kubectl logs`
  of chatty pods stalls. Hard to spot because small packets pass.
- **Root cause**: Tailscale (WireGuard) MTU is 1280. Calico VXLAN default is
  1450. VXLAN-in-WireGuard fragments anything > 1230.
- **Diagnostic**:
  ```bash
  ip link show tailscale0     # mtu 1280
  ip link show | grep vxlan   # vxlan.calico mtu 1450 → mismatch
  ```
- **Fix**: lower Calico VXLAN MTU to 1230 (Tailscale 1280 − 50 encapsulation):
  ```bash
  microk8s.kubectl -n kube-system patch felixconfiguration default \
    --type merge -p '{"spec":{"vxlanMTU":1230}}'
  ```

### 5. `tailscaled` instability on worker nodes

- **Symptom**: workers drop in waves at different times (not all at once).
  Pi nodes especially — SD-card corruption, power blips, OOM kills.
- **Root cause**: the `tailscaled` process on individual nodes dies or sleeps,
  cutting that node's VPN link while others stay up.
- **Diagnostic** (on the affected node):
  ```bash
  systemctl status tailscaled
  journalctl -u tailscaled --since "1h ago" | tail -30
  tailscale status    # peers should be "active"/"direct", not "relay"/"offline"
  ```
- **Fix**: ensure `tailscaled` is `restart=always`, monitor it. The recovery
  script restarts it as part of the flow.

### 6. Node went physically offline

- **Symptom**: node's lease hasn't renewed for hours. Pi node silent for 16h+.
- **Root cause**: the node is powered off, network cable unplugged, or so
  wedged it can't reach Tailscale at all.
- **Diagnostic**: can you SSH to the node? Does it respond to `ping` on its
  LAN IP? `kubectl get lease <node> -n kube-node-lease` shows stale renewTime.
- **Fix**: power-cycle the node, fix hardware, then run the recovery script.

## When to use which script

```
Is this a brand-new node (fresh OS, nothing installed yet)?
├── YES → setup-microk8s-tailscale-node.sh
│         ├── control plane → sudo ./setup-... init
│         └── worker        → sudo ./setup-... join "<add-node line>"
│
└── NO (node already has microk8s + Tailscale, but is NotReady)
    └── recover-microk8s-tailscale-node.sh
        └── sudo ./recover-... [api-server-tailscale-ip]
```

Both scripts are idempotent — safe to re-run. The recovery script in particular
is designed to be run repeatedly: each step checks current state and skips
work that's already correct.

## New cluster setup (end-to-end)

```bash
# 1. Control-plane node
scp -r scripts/microk8s_tailscaled user@cp-node:/tmp/
ssh user@cp-node 'sudo /tmp/microk8s_tailscaled/setup-microk8s-tailscale-node.sh init'
# Script prints the join string (or run `microk8s add-node` after).

# 2. Each worker node
scp -r scripts/microk8s_tailscaled user@worker:/tmp/
ssh user@worker 'sudo /tmp/microk8s_tailscaled/setup-microk8s-tailscale-node.sh join \
  "microk8s join 100.x.x.x:25000/token"'

# 3. From operator machine, verify
kubectl get nodes -o wide   # all Ready
```

## Recovering an existing broken cluster

For nodes already deployed the naive way (kubelet pinned to LAN IP):

```bash
# On each NotReady node (pass control-plane Tailscale IP for connectivity test):
ssh user@microk8s-1 "sudo bash -s 100.104.141.106" \
  < scripts/microk8s_tailscaled/recover-microk8s-tailscale-node.sh

# Also run on the control plane (no IP arg) — fixes its cert too:
ssh user@raspberrypi2 'sudo bash -s' \
  < scripts/microk8s_tailscaled/recover-microk8s-tailscale-node.sh
```

The connectivity test in the recovery script immediately surfaces failure
mode #3 (ACLs) or #5 (tailscaled) — much faster than guessing.

## What the scripts cannot fix (require manual action)

| Issue | Where to fix | How |
|---|---|---|
| Tailscale ACLs blocking k8s ports | Tailscale admin console | Add allow rule for `tcp:16443,10250,25000,19001-19010` between cluster nodes |
| Calico VXLAN MTU mismatch | Control plane (one-time) | `kubectl patch felixconfiguration default --type merge -p '{"spec":{"vxlanMTU":1230}}'` |
| Single control plane (no HA) | Architectural | Add 2 more control-plane nodes via `microk8s add-node` |
| Dead hardware / powered-off Pi | Physical | Power-cycle, then run recovery |

## Verification checklist

After setup or recovery, all of these should be true:

```bash
# 1. All nodes Ready
kubectl get nodes                   # every node Ready, no Unknown

# 2. Kubelet serving cert includes the node's Tailscale IP (run on each node)
openssl x509 -in /var/snap/microk8s/current/certs/kubelet.crt -noout -ext subjectAltName
#   Must show: IP Address:100.x.x.x (the Tailscale IP). DNS-only = broken.

# 3. API server can talk to kubelets (proxy healthz works)
kubectl get --raw='/api/v1/nodes/<node>/proxy/healthz'   # should return "ok"

# 4. Node leases renewing (sharp signal — updates every ~10s)
kubectl get lease -n kube-node-lease # renewTime should be < 1 min ago for live nodes

# 5. kubectl logs works (the cert-SAN integration test)
kubectl logs <any-pod>               # no TLS/x509 error
```

If any of these fails, match the symptom to the failure modes above.

## Provenance

These scripts and findings were derived from a real incident (2026-07-05/06)
on a 5-node mixed-arch cluster (3 Raspberry Pi ARM64 + 2 amd64 microk8s)
where 4 of 5 nodes were stuck `NotReady`. Root cause was the kubelet
serving cert lacking Tailscale IP SANs, compounded by a single control
plane and per-node `tailscaled` instability. The investigation evidence
lives in `Daily Notes/070526.md` and `Daily Notes/070626.md`.

**Updated 2026-07-12**: the original "delete cert + restart kubelet" fix
was proven wrong on raspi3 — microk8s's kubelet auto-regeneration produces
a DNS-only cert (no IP SANs) regardless of `--node-ip`. Recovery and setup
scripts now generate the serving cert explicitly with IP SANs, signed by
the microk8s CA. Also adopted the IP-first design principle (prefer IPs
over names everywhere; full MagicDNS name as fallback if a name is needed).
