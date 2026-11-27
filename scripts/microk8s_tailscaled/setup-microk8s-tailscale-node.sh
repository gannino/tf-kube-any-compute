#!/usr/bin/env bash
# Install microk8s + Tailscale on a fresh Ubuntu node, configured for
# Tailscale-only networking from day one.
#
# This is the hardened version of the bare-bones install. It pins the kubelet
# --node-ip to the Tailscale IP BEFORE the kubelet first generates its serving
# certificate, so the cert's SAN includes the Tailscale IP from the start.
# Run this on a fresh node and you will never need recover-microk8s-tailscale-node.sh.
#
# Two modes:
#   init : control-plane node — initializes a new cluster, prints a join string
#   join : worker node — joins an existing cluster
#
# Usage:
#   sudo ./setup-microk8s-tailscale-node.sh init
#   sudo ./setup-microk8s-tailscale-node.sh join "<line-from-microk8s-add-node>"
#
# The "join" argument is the FULL line printed by `microk8s add-node` on the
# control plane, e.g.:  microk8s join 100.104.141.106:25000/abc123/def456
# (the leading "microk8s join " is optional — the script strips it.)
#
# Env overrides:
#   MICROK8S_CHANNEL  snap channel (default: 1.35/stable)
#   TS_EXTRA_ARGS     extra flags passed to `tailscale up`
#   SKIP_APT_UPGRADE  set to "1" to skip `apt upgrade` (faster, less disruptive)

set -uo pipefail

MODE="${1:-}"
JOIN_INPUT="${2:-}"
MICROK8S_CHANNEL="${MICROK8S_CHANNEL:-1.35/stable}"
TS_EXTRA_ARGS="${TS_EXTRA_ARGS:-}"
SKIP_APT_UPGRADE="${SKIP_APT_UPGRADE:-0}"

KUBELET_ARGS=/var/snap/microk8s/current/args/kubelet

# --- pretty output ---
c_red()    { printf '\033[31m%s\033[0m\n' "$*"; }
c_green()  { printf '\033[32m%s\033[0m\n' "$*"; }
c_yellow() { printf '\033[33m%s\033[0m\n' "$*"; }
c_blue()   { printf '\033[34m%s\033[0m\n' "$*"; }
c_bold()   { printf '\033[1m%s\033[0m\n' "$*"; }
step()     { c_blue "▶ $*"; }
ok()       { c_green "  ✓ $*"; }
warn()     { c_yellow "  ⚠ $*"; }
die()      { c_red "  ✗ $*"; exit 1; }

# --- pre-flight ---
[ "$(id -u)" -eq 0 ] || die "Run with sudo"
case "$MODE" in
  init) : ;;
  join) [ -n "$JOIN_INPUT" ] || die "join mode requires the add-node line as second argument" ;;
  *)    c_red "Usage:"; echo "  sudo $0 init"; echo "  sudo $0 join \"<line-from-microk8s-add-node>\""; exit 1 ;;
esac

# Detect / install snapd
command -v snap >/dev/null 2>&1 || {
  step "Installing snapd"
  apt update -qq || die "apt update failed"
  apt install -y -qq snapd || die "snapd install failed"
  systemctl enable --now snapd
  # snap command may need PATH refresh
  export PATH="$PATH:/snap/bin"
}

NODE_NAME=$(hostname)

# ============================================================
# STEP 1: Tailscale install + up
# ============================================================
step "Tailscale"
if command -v tailscale >/dev/null 2>&1; then
  ok "tailscale already installed"
else
  . /etc/os-release
  CODENAME="${UBUNTU_CODENAME:-noble}"
  curl -fsSL "https://pkgs.tailscale.com/stable/ubuntu/${CODENAME}.noarmor.gpg" \
    | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
  curl -fsSL "https://pkgs.tailscale.com/stable/ubuntu/${CODENAME}.tailscale-keyring.list" \
    | tee /etc/apt/sources.list.d/tailscale.list >/dev/null
  apt update -qq
  apt install -y -qq tailscale || die "tailscale install failed"
  ok "tailscale installed"
fi

systemctl enable --now tailscaled >/dev/null 2>&1 || true

if [ "$SKIP_APT_UPGRADE" != "1" ]; then
  step "apt upgrade (set SKIP_APT_UPGRADE=1 to skip)"
  apt install -y -qq jq netcat-openbsd iperf htop nano net-tools nfs-common cifs-utils >/dev/null 2>&1 || true
  apt upgrade -y -qq || warn "apt upgrade had issues (non-fatal)"
fi

# Bring Tailscale up with a stable hostname (idempotent — `up` is safe to re-run)
step "tailscale up"
TS_UP_CMD="tailscale up --hostname=$NODE_NAME --accept-routes $TS_EXTRA_ARGS"
if tailscale ip -4 >/dev/null 2>&1; then
  ok "already authenticated to Tailscale"
else
  # shellcheck disable=SC2086
  $TS_UP_CMD || die "tailscale up failed — run '$TS_UP_CMD' manually to authenticate"
fi

TS_IP=$(tailscale ip -4 2>/dev/null | head -1)
[ -n "$TS_IP" ] || die "No Tailscale IPv4 after up — check 'tailscale status'"
ok "Tailscale IP: $TS_IP"

# ============================================================
# STEP 2: microk8s install
# ============================================================
step "microk8s"
if command -v microk8s >/dev/null 2>&1; then
  ok "microk8s already installed"
else
  snap install microk8s --classic --channel="$MICROK8S_CHANNEL" || die "microk8s install failed"
  # Ensure the microk8s group + PATH work for non-root later, but snap commands work as root now
  ok "microk8s installed (channel $MICROK8S_CHANNEL)"
fi

# Wait for microk8s to be ready for the first time (bootstrap)
step "Wait for microk8s first boot (up to 240s)"
READY=0
for _ in $(seq 1 80); do
  if microk8s.status --wait-ready --timeout 30 >/dev/null 2>&1; then READY=1; break; fi
  sleep 3
done
[ "$READY" -eq 1 ] || die "microk8s not ready after 240s — check 'snap logs microk8s'"
ok "microk8s ready"

# ============================================================
# STEP 3: Pin kubelet --node-ip to the Tailscale IP (BEFORE cert gen on restart)
# ============================================================
step "Pin kubelet --node-ip = $TS_IP"
[ -f "$KUBELET_ARGS" ] || die "kubelet args file not found at $KUBELET_ARGS"
CURRENT_NODE_IP=$(grep -E '^--node-ip=' "$KUBELET_ARGS" 2>/dev/null | cut -d= -f2 || true)
if [ "$CURRENT_NODE_IP" = "$TS_IP" ]; then
  ok "already pinned to $TS_IP"
else
  if [ -n "$CURRENT_NODE_IP" ]; then
    sed -i "s|^--node-ip=.*|--node-ip=$TS_IP|" "$KUBELET_ARGS"
  else
    echo "--node-ip=$TS_IP" >> "$KUBELET_ARGS"
  fi
  ok "pinned --node-ip=$TS_IP"
fi

# ============================================================
# STEP 4: Enable required addons (dns is mandatory; others optional)
# ============================================================
step "Enable microk8s addons"
microk8s.enable dns 2>/dev/null && ok "dns enabled" || warn "dns enable failed or already on"

# ============================================================
# STEP 5: Generate kubelet serving cert with explicit IP SANs
#
# microk8s's kubelet auto-generates a serving cert on first start, but it only
# stamps the hostname as SAN — NOT interface IPs. If we leave it, the API server
# will fail TLS verification when connecting to the kubelet by Tailscale IP.
# So we generate the cert explicitly with IP SANs, signed by microk8s's CA.
# IP-first design; DNS names (localhost + full MagicDNS) are fallback only.
# ============================================================
step "Generate kubelet serving cert with IP SANs"

LAN_IP=$(ip -4 route get 192.0.2.1 2>/dev/null | grep -oP 'src \K[\d.]+' | head -1 || true)
MAGIC_DNS=$(timeout 5 tailscale status --json 2>/dev/null | jq -r '.Self.DNSName // empty' 2>/dev/null | sed 's/\.$//' || true)
CERTS_DIR=/var/snap/microk8s/current/certs
KUBELET_CERT=$CERTS_DIR/kubelet.crt
SAN_CONF=/tmp/kubelet-san.${NODE_NAME}.cnf

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

openssl req -new -newkey rsa:2048 -nodes \
  -keyout "$CERTS_DIR/kubelet.key.new" \
  -out "$CERTS_DIR/kubelet.csr" \
  -config "$SAN_CONF" 2>/dev/null || die "CSR generation failed"
openssl x509 -req -in "$CERTS_DIR/kubelet.csr" \
  -CA "$CERTS_DIR/ca.crt" -CAkey "$CERTS_DIR/ca.key" -CAcreateserial \
  -out "$CERTS_DIR/kubelet.crt.new" -days 365 -sha256 \
  -extensions v3_req -extfile "$SAN_CONF" 2>/dev/null || die "cert signing failed"

# SANITY CHECK before install — must carry the Tailscale IP
if openssl x509 -in "$CERTS_DIR/kubelet.crt.new" -noout -ext subjectAltName 2>/dev/null | grep -q "IP Address:$TS_IP"; then
  mv "$CERTS_DIR/kubelet.crt.new" "$KUBELET_CERT"
  mv "$CERTS_DIR/kubelet.key.new" "${KUBELET_CERT%.crt}.key"
  chown root:root "$KUBELET_CERT" "${KUBELET_CERT%.crt}.key"
  chmod 644 "$KUBELET_CERT"
  chmod 600 "${KUBELET_CERT%.crt}.key"
  ok "serving cert installed (SAN includes IP:$TS_IP)"
else
  die "new cert does not include IP:$TS_IP — aborting before install"
fi

# Restart kubelet so it serves our explicit cert (not its auto-generated one)
snap restart microk8s.daemon-kubelet >/dev/null 2>&1 || warn "kubelet restart non-zero (cert still installed on disk)"
sleep 5

# ============================================================
# STEP 6: Mode-specific action (init cluster OR join cluster)
# ============================================================
if [ "$MODE" = "init" ]; then
  step "Generate kubeconfig"
  microk8s.config > /root/.kube/config 2>/dev/null && ok "/root/.kube/config written" || warn "config write failed"

  # IP-first: make the apiserver resolve kubelets by InternalIP (the Tailscale IP)
  # before falling back to hostname. Default is Hostname,InternalIP,ExternalIP which
  # tries a name lookup first and depends on MagicDNS. Reorder so it uses the IP.
  step "Configure apiserver to prefer IPs over hostname (IP-first)"
  APISERVER_ARGS=/var/snap/microk8s/current/args/kube-apiserver
  if [ -f "$APISERVER_ARGS" ]; then
    if grep -q '^--kubelet-preferred-address-types=' "$APISERVER_ARGS" 2>/dev/null; then
      sed -i 's|^--kubelet-preferred-address-types=.*|--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname|' "$APISERVER_ARGS"
    else
      echo "--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname" >> "$APISERVER_ARGS"
    fi
    snap restart microk8s.daemon-apiserver >/dev/null 2>&1 || warn "apiserver restart non-zero (arg still written to disk)"
    ok "apiserver will reach kubelets by InternalIP first"
  else
    warn "apiserver args file not found at $APISERVER_ARGS — skipping"
  fi

  step "MTU alignment check (Tailscale + Calico)"
  TS_MTU=$(ip link show tailscale0 2>/dev/null | grep -oE 'mtu [0-9]+' | awk '{print $2}')
  if [ -n "$TS_MTU" ] && [ "$TS_MTU" -lt 1400 ]; then
    RECOMMENDED=$((TS_MTU - 50))
    warn "Tailscale MTU=$TS_MTU — set Calico VXLAN MTU <= $RECOMMENDED to avoid large-packet fragmentation"
    warn "  fix: microk8s.kubectl -n kube-system patch felixconfiguration default --type merge \\"
    warn "         -p '{\"spec\":{\"vxlanMTU\":$RECOMMENDED}}'"
  fi

  echo ""
  c_green "========================================"
  c_green "Control plane ready: $NODE_NAME ($TS_IP)"
  c_green "========================================"
  echo ""
  c_bold "Next: add worker nodes. Run this on the control plane to get a join string:"
  echo "   microk8s add-node"
  echo ""
  c_bold "Then on each worker node, run:"
  echo "   sudo ./setup-microk8s-tailscale-node.sh join \"<the 'microk8s join ...' line printed above>\""

else
  # JOIN mode
  step "Join cluster"
  # Strip a leading "microk8s join " if the user pasted the whole line
  JOIN_TOKEN="${JOIN_INPUT#microk8s join }"
  [ -n "$JOIN_TOKEN" ] || die "could not parse join token from: $JOIN_INPUT"

  # microk8s join is idempotent-ish; if already joined, it errors harmlessly
  if microk8s join "$JOIN_TOKEN" 2>&1; then
    ok "join command succeeded"
  else
    warn "join command returned non-zero — node may already be joined, or the token expired"
    warn "  verify with: microk8s.kubectl get nodes"
  fi

  step "Wait for this node to appear in cluster (up to 120s)"
  for _ in $(seq 1 40); do
    if microk8s.kubectl get node "$NODE_NAME" >/dev/null 2>&1; then
      ok "$NODE_NAME registered in cluster"
      microk8s.kubectl get node "$NODE_NAME" -o wide || true
      break
    fi
    sleep 3
  done
fi

# ============================================================
# STEP 7: Final verification
# ============================================================
step "microk8s ready check"
microk8s.status --wait-ready --timeout 60 >/dev/null 2>&1 && ok "microk8s ready" || warn "not ready yet"

echo ""
c_green "========================================"
c_green "Setup complete on $NODE_NAME ($TS_IP)"
c_green "========================================"
echo ""
echo "From the operator machine, verify:"
echo "  kubectl get nodes -o wide"
echo ""
echo "All nodes should show Ready within ~60s. If a node shows NotReady:"
echo "  sudo ./scripts/microk8s_tailscaled/recover-microk8s-tailscale-node.sh"
