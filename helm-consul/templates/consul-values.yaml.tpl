# Configure global settings in this section.
global:
  name: ${name}
  # Bootstrap ACLs within Consul. This is highly recommended.
  acls:
    manageSystemACLs: true
    resources:
      requests:
        memory: '128Mi'
        cpu: '100m'
      limits:
        memory: '256Mi'
        cpu: '150m'
  # Gossip encryption
  gossipEncryption:
    secretName: ${namespace}-gossip-encryption-key
    secretKey: key
  # Set datacenter name
  datacenter: dc1
  # Configure for ARM architecture (Raspberry Pi)
  image: "hashicorp/consul:${consul_image_version}"
  imageK8S: "hashicorp/consul-k8s-control-plane:${consul_k8s_image_version}"

# Configure your Consul servers in this section.
server:
  # For 3 Raspberry Pis, use 3 replicas for proper consensus
  replicas: 3
  # Optimized resources for Raspberry Pi with new limits
  resources:
    requests:
      memory: ${memory_request}
      cpu: ${cpu_request}
    limits:
      memory: ${memory_limit}
      cpu: ${cpu_limit}
  # Storage configuration
  storage: ${persistent_disk_size}
  storageClass: ${storage_class}
  # Affinity rules to ensure servers are spread across nodes
  affinity: |
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
            - key: app
              operator: In
              values:
              - consul
            - key: component
              operator: In
              values:
              - server
          topologyKey: kubernetes.io/hostname

# Configure Consul clients in this section
client:
  enabled: true
  # Optimized resources for Raspberry Pi clients
  resources:
    requests:
      memory: '128Mi'
      cpu: '100m'
    limits:
      memory: '256Mi'
      cpu: '200m'

# Enable and configure the Consul UI.
ui:
  enabled: true
  service:
    type: ClusterIP

# Enable Consul connect pod injection (commented out for basic setup)
connectInject:
  enabled: false
#   default: false
  apiGateway:
    enabled: false

# Controller for CRDs
controller:
  enabled: true
  # Optimized resources for Raspberry Pi controller
  resources:
    requests:
      memory: '64Mi'
      cpu: '50m'
    limits:
      memory: '128Mi'
      cpu: '100m'

# DNS configuration
dns:
  enabled: true
  type: ClusterIP
