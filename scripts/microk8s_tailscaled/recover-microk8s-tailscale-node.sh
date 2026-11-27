#!/usr/bin/env bash
# Recover a NotReady microk8s node operating over Tailscale.
#
# Fixes the three things that make microk8s flap on a Tailscale-only network:
#   1. kubelet --node-ip not set to the Tailscale IP   (node advertises wrong IP)
#   2. kubelet serving cert lacks the Tailscale IP SAN (API server -> kubelet TLS fails)
#   3. tailscaled not running / not authenticated      (heartbeats can't cross VPN)
#
# Design principle: IP-first. The cluster operates on Tailscale IPs, not names —
# no dependency on MagicDNS resolution. The serving cert is generated explicitly
# with IP SANs (microk8s's auto-regen only stamps hostname). DNS SANs are included
# as fallback insurance only (localhost + the full MagicDNS name; short hostnames
# don't resolve without a tailnet search domain).
#
# Run ON the affected node via SSH, as root (sudo).
# Idempotent: safe to run multiple times. Works for control-plane and worker nodes.
#
# Usage: sudo ./recover-microk8s-tailscale-node.sh [api-server-tailscale-ip]
#   api-server-tailscale-ip: the control-plane node's Tailscale IP, for a connectivity
#                            test. Optional but recommended on worker nodes.

set -uo pipefail

API_SERVER_IP="${1:-}"
KUBELET_ARGS=/var/snap/microk8s/current/args/kubelet
KUBELET_CERT=/var/snap/microk8s/current/certs/kubelet.crt

# --- pretty output ---
c_red()    { printf '\033[31m%s\033[0m\n' "$*"; }
c_green()  { printf '\033[32m%s\033[0m\n' "$*"; }
c_yellow() { printf '\033[33m%s\033[0m\n' "$*"; }
c_blue()   { printf '\033[34m%s\033[0m\n' "$*"; }
step()     { c_blue "▶ $*"; }
ok()       { c_green "  ✓ $*"; }
warn()     { c_yellow "  ⚠ $*"; }
die()      { c_red "  ✗ $*"; exit 1; }

# --- pre-flight ---
[ "$(id -u)" -eq 0 ] || die "Run with sudo (needs root for snap/systemctl/cert files)"
command -v tailscale >/dev/null 2>&1 || die "tailscale CLI not installed"
command -v microk8s >/dev/null 2>&1 || die "microk8s not installed"
[ -f "$KUBELET_ARGS" ] || die "kubelet args file not found at $KUBELET_ARGS"

NODE_NAME=$(hostname)

# ============================================================
# STEP 1: Tailscale health
# ============================================================
step "Tailscale daemon"
systemctl enable --now tailscaled >/dev/null 2>&1 || true
if ! systemctl is-active --quiet tailscaled; then
  warn "tailscaled not active — restarting"
  systemctl restart tailscaled
  sleep 5
fi
systemctl is-active --quiet tailscaled || die "tailscaled failed to start"

TS_IP=$(tailscale ip -4 2>/dev/null | head -1 || true)
[ -n "$TS_IP" ] || die "No Tailscale IPv4. Run 'sudo tailscale up' first, then re-run this script."
ok "Tailscale up, this node IP: $TS_IP"

# Optional: connectivity test to the API server over Tailscale
if [ -n "$API_SERVER_IP" ]; then
  step "Tailscale path to API server ($API_SERVER_IP)"
  if tailscale ping -c 1 --timeout 5s "$API_SERVER_IP" >/dev/null 2>&1; then
    ok "Tailscale reachable to API server"
  else
    warn "tailscale ping failed — link may be using DERP relay or is down"
    warn "  check: tailscale status   (look for 'offline' or 'relay' peers)"
  fi
  if timeout 5 bash -c "true <>/dev/tcp/$API_SERVER_IP/16443" 2>/dev/null; then
    ok "API server port 16443 reachable over Tailscale"
  else
    warn "API server port 16443 NOT reachable — check Tailscale ACLs allow k8s ports"
    warn "  ACL must allow: tcp:16443 (apiserver), tcp:10250 (kubelet),"
    warn "                  tcp:19001-19010 (dqlite HA, if used)"
  fi
fi

# ============================================================
# STEP 2: Pin kubelet --node-ip to the Tailscale IP
# ============================================================
step "Configure kubelet --node-ip = $TS_IP"
CURRENT_NODE_IP=$(grep -E '^--node-ip=' "$KUBELET_ARGS" 2>/dev/null | cut -d= -f2 || true)
if [ "$CURRENT_NODE_IP" = "$TS_IP" ]; then
  ok "kubelet --node-ip already pinned to $TS_IP"
else
  if [ -n "$CURRENT_NODE_IP" ]; then
    warn "was $CURRENT_NODE_IP (probably a LAN IP — root cause of cert SAN issue)"
    sed -i "s|^--node-ip=.*|--node-ip=$TS_IP|" "$KUBELET_ARGS"
  else
    echo "--node-ip=$TS_IP" >> "$KUBELET_ARGS"
  fi
  ok "pinned --node-ip=$TS_IP"
fi

# ============================================================
# STEP 3: Generate kubelet serving cert with explicit IP SANs
#
# Why explicit: microk8s's kubelet auto-generates a serving cert on restart,
# but it only stamps the hostname as SAN — it does NOT enumerate interface
# IPs. So "delete + restart" gives you a DNS-only cert every time, and the
# API server fails TLS when connecting to the kubelet by IP.
#
# Fix: generate the cert explicitly with IP SANs (Tailscale IP primary),
# signed by microk8s's own CA. Design principle: IP-first ("IP not names").
# DNS entries are fallback insurance only — localhost + the FULL MagicDNS
# name (short hostnames don't resolve without a tailnet search domain).
# ============================================================
step "Generate kubelet serving cert with IP SANs"

# Detect additional addresses to include in the SAN
LAN_IP=$(ip -4 route get 192.0.2.1 2>/dev/null | grep -oP 'src \K[\d.]+' | head -1 || true)
MAGIC_DNS=$(timeout 5 tailscale status --json 2>/dev/null | jq -r '.Self.DNSName // empty' 2>/dev/null | sed 's/\.$//' || true)
CERTS_DIR=/var/snap/microk8s/current/certs
SAN_CONF=/tmp/kubelet-san.${NODE_NAME}.cnf

# Build SAN config (IPs first, then DNS as fallback)
{
  echo "[req]"
  echo "distinguished_name = req_distinguished_name"
  echo "req_extensions = v3_req"
  echo "prompt = no"
  echo "[req_distinguished_name]"
  echo "CN = $NODE_NAME"
  echo "[v3_req]"
  echo "keyUsage = critical, digitalSignature, keyEncipherment"
  echo "extendedKeyUsage = serverAuth"
  echo "subjectAltName = @alt_names"
  echo "[alt_names]"
  echo "DNS.1 = localhost"
  echo "IP.1 = 127.0.0.1"
  echo "IP.2 = $TS_IP"
  ip_n=3
  [ -n "$LAN_IP" ] && { echo "IP.$ip_n = $LAN_IP"; ip_n=$((ip_n+1)); }
  dns_n=2
  [ -n "$MAGIC_DNS" ] && { echo "DNS.$dns_n = $MAGIC_DNS"; dns_n=$((dns_n+1)); }
  echo "DNS.$dns_n = $NODE_NAME"
} > "$SAN_CONF"
ok "SAN: IPs [127.0.0.1, $TS_IP${LAN_IP:+, $LAN_IP}]${MAGIC_DNS:+, DNS [$MAGIC_DNS, $NODE_NAME]}"

# If current cert already covers the Tailscale IP, skip regeneration
if [ -f "$KUBELET_CERT" ] && openssl x509 -in "$KUBELET_CERT" -noout -ext subjectAltName 2>/dev/null | grep -q "IP Address:$TS_IP"; then
  ok "existing cert already covers IP:$TS_IP — skipping regeneration"
else
  # Back up current cert before touching it
  if [ -f "$KUBELET_CERT" ]; then
    cp "$KUBELET_CERT" "$CERTS_DIR/kubelet.crt.bak.$(date +%s)"
    cp "${KUBELET_CERT%.crt}.key" "$CERTS_DIR/kubelet.key.bak.$(date +%s)" 2>/dev/null || true
  fi

  # Generate new key + CSR, sign with the microk8s CA
  openssl req -new -newkey rsa:2048 -nodes \
    -keyout "$CERTS_DIR/kubelet.key.new" \
    -out "$CERTS_DIR/kubelet.csr" \
    -config "$SAN_CONF" 2>/dev/null || die "CSR generation failed"
  openssl x509 -req -in "$CERTS_DIR/kubelet.csr" \
    -CA "$CERTS_DIR/ca.crt" -CAkey "$CERTS_DIR/ca.key" -CAcreateserial \
    -out "$CERTS_DIR/kubelet.crt.new" -days 365 -sha256 \
    -extensions v3_req -extfile "$SAN_CONF" 2>/dev/null || die "cert signing failed"

  # SANITY CHECK: confirm the new cert actually carries the Tailscale IP BEFORE installing
  if openssl x509 -in "$CERTS_DIR/kubelet.crt.new" -noout -ext subjectAltName 2>/dev/null | grep -q "IP Address:$TS_IP"; then
    mv "$CERTS_DIR/kubelet.crt.new" "$KUBELET_CERT"
    mv "$CERTS_DIR/kubelet.key.new" "${KUBELET_CERT%.crt}.key"
    chown root:root "$KUBELET_CERT" "${KUBELET_CERT%.crt}.key"
    chmod 644 "$KUBELET_CERT"
    chmod 600 "${KUBELET_CERT%.crt}.key"
    ok "new serving cert installed (SAN includes IP:$TS_IP)"
  else
    die "new cert does not include IP:$TS_IP — aborting before install, old cert preserved"
  fi
fi

# ============================================================
# STEP 4: Restart kubelet so it serves the new cert
# ============================================================
step "Restart microk8s.daemon-kubelet"
if snap restart microk8s.daemon-kubelet >/dev/null 2>&1; then
  ok "kubelet restarted"
else
  warn "targeted restart failed — falling back to full microk8s restart"
  snap restart microk8s || die "microk8s restart failed"
fi

# ============================================================
# STEP 5: Wait for microk8s ready
# ============================================================
step "Wait for microk8s ready (up to 180s)"
READY=0
for _ in $(seq 1 60); do
  if microk8s.status --wait-ready --timeout 30 >/dev/null 2>&1; then
    READY=1; break
  fi
  sleep 3
done
[ "$READY" -eq 1 ] || die "microk8s not ready after 180s — check 'journalctl -u snap.microk8s.daemon-kubelet'"
ok "microk8s ready"

# ============================================================
# STEP 6: Verify cert serves the Tailscale IP
# ============================================================
step "Verify kubelet serving cert"
sleep 5
if openssl x509 -in "$KUBELET_CERT" -noout -ext subjectAltName 2>/dev/null | grep -q "IP Address:$TS_IP"; then
  ok "kubelet serving cert includes IP:$TS_IP"
  openssl x509 -in "$KUBELET_CERT" -noout -ext subjectAltName 2>/dev/null | sed 's/^/  /'
else
  warn "cert still missing IP:$TS_IP — manual investigation needed"
  warn "  openssl x509 -in $KUBELET_CERT -noout -ext subjectAltName"
fi

# ============================================================
# STEP 7: MTU alignment check (warn-only — fixing is invasive)
# ============================================================
step "MTU alignment (Tailscale + Calico)"
TS_MTU=$(ip link show tailscale0 2>/dev/null | grep -oE 'mtu [0-9]+' | awk '{print $2}')
if [ -n "$TS_MTU" ]; then
  ok "tailscale0 MTU: $TS_MTU"
  # Calico VXLAN MTU should be <= TS_MTU - 50
  if [ "$TS_MTU" -lt 1400 ]; then
    warn "Tailscale MTU=$TS_MTU is low — ensure Calico VXLAN MTU <= $((TS_MTU - 50))"
    warn "  otherwise large packets (cert rotations, big ConfigMaps) will fragment and fail"
  fi
else
  warn "could not read tailscale0 MTU (interface down?)"
fi

# ============================================================
# STEP 8: Report
# ============================================================
echo ""
c_green "========================================"
c_green "Recovery complete on $NODE_NAME ($TS_IP)"
c_green "========================================"
echo ""
echo "From the operator machine, verify the node rejoined:"
echo "  kubectl get nodes -o wide"
echo ""
echo "If still NotReady after 60s, inspect on this node:"
echo "  sudo journalctl -u snap.microk8s.daemon-kubelet --since '3 min ago' | tail -30"
echo "  sudo journalctl -u tailscaled                  --since '3 min ago' | tail -20"
echo "  sudo tailscale status   (peers should be 'active', not 'offline'/'relay')"
