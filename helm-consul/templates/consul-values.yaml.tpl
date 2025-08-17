# Configure global settings in this section.
global:
  name: ${name}
  # Bootstrap ACLs within Consul. This is highly recommended.
  acls:
    manageSystemACLs: true
  resources:
    requests:
      memory: ${memory_request}
      cpu: ${cpu_request}
    limits:
      memory: ${memory_limit}
      cpu: ${cpu_limit}
    # # IMPROVEMENT: Add token replication for multi-DC setups
    # replicationToken:
    #   secretName: "${name}-acl-replication-token"
    #   secretKey: "token"

  # Gossip encryption
  gossipEncryption:
    secretName: ${namespace}-gossip-encryption-key
    secretKey: key

  # Set datacenter name
  datacenter: dc1

  # # IMPROVEMENT: Add domain configuration for proper DNS
  # domain: consul

  # Configure for ARM architecture (Raspberry Pi)
  image: "hashicorp/consul:${consul_image_version}"
  imageK8S: "hashicorp/consul-k8s-control-plane:${consul_k8s_image_version}"

  # IMPROVEMENT: Add image pull policy for consistent deployments
  imagePullPolicy: IfNotPresent

  # IMPROVEMENT: Add global logging configuration
  logLevel: "INFO"
  logJSON: true

  # IMPROVEMENT: Enable metrics for monitoring
  metrics:
    enabled: true
    enableAgentMetrics: true
    agentMetricsRetentionTime: "1m"

# Configure your Consul servers in this section.
server:
  # Configurable replicas for different cluster sizes
  replicas: ${server_replicas}

  # # IMPROVEMENT: Add bootstrap expect for proper cluster formation
  # bootstrapExpect: ${server_replicas}

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

  # Enable agent debug (replaces enable_debug in extraConfig)
  enableAgentDebug: false

  # IMPROVEMENT: Add server configuration for better service management
  extraConfig: |
    {
      "log_level": "INFO",
      "session_ttl_min": "10s",
      "ui_config": {
        "enabled": true
      },
      "connect": {
        "enabled": true
      },
      "auto_reload_config": true,
      "leave_on_terminate": true,
      "rejoin_after_leave": true,
      "disable_update_check": true,
      "check_update_interval": "0s"
    }

  # IMPROVEMENT: Add update strategy for rolling updates
  updatePartition: 0

  # IMPROVEMENT: Enhanced affinity rules - conditional based on enable_pod_anti_affinity
%{ if enable_pod_anti_affinity ~}
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
    nodeAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        preference:
          matchExpressions:
          - key: node-role.kubernetes.io/control-plane
            operator: DoesNotExist
%{ endif ~}

  # IMPROVEMENT: Add tolerations for node taints
  tolerations: []

  # IMPROVEMENT: Add security context
  securityContext:
    runAsNonRoot: true
    runAsUser: 100
    fsGroup: 1000

  # # IMPROVEMENT: Add disruption budget
  # disruptionBudget:
  #   enabled: true
  #   maxUnavailable: 1

# Configure Consul clients in this section
client:
  enabled: true
%{ if client_replicas > 0 ~}
  # Fixed number of client replicas
  replicas: ${client_replicas}
%{ else ~}
  # DaemonSet mode - one client per node
  # (default Helm chart behavior when replicas not specified)
%{ endif ~}

  # Optimized resources for Raspberry Pi clients
  resources:
    requests:
      memory: ${memory_request}
      cpu: ${cpu_request}
    limits:
      memory: ${memory_limit}
      cpu: ${cpu_limit}

  # IMPROVEMENT: Client-specific configuration
  extraConfig: |
    {
      "log_level": "INFO",
      "leave_on_terminate": true,
      "rejoin_after_leave": true,
      "disable_update_check": true,
      "check_update_interval": "0s"
    }

  # IMPROVEMENT: Add security context for clients
  securityContext:
    runAsNonRoot: true
    runAsUser: 100
    fsGroup: 1000

  # IMPROVEMENT: Node selector for client placement
  nodeSelector: {}

  # IMPROVEMENT: Tolerations for client pods
  tolerations: |
    - effect: NoSchedule
      key: node-role.kubernetes.io/control-plane
      operator: Exists

# Enable and configure the Consul UI.
ui:
  enabled: true
  service:
    type: ClusterIP
    # IMPROVEMENT: Add additional service annotations for ingress
    annotations:
      # Add your ingress class annotation here
      # kubernetes.io/ingress.class: "nginx"

# IMPROVEMENT: Enhanced Connect Inject configuration - DISABLED initially
connectInject:
  enabled: false  # Disabled to avoid conflicts
  default: false  # Opt-in per service

  # Add failurePolicy for webhook
  failurePolicy: Ignore

  # IMPROVEMENT: Add init container resources
  initContainer:
    resources:
      requests:
        memory: ${memory_request}
        cpu: ${cpu_request}
      limits:
        memory: ${memory_limit}
        cpu: ${cpu_limit}

  # IMPROVEMENT: Add sidecar proxy resources
  sidecarProxy:
    resources:
      requests:
        memory: ${memory_request}
        cpu: ${cpu_request}
      limits:
        memory: ${memory_limit}
        cpu: ${cpu_limit}

  # API Gateway configuration
  apiGateway:
    enabled: false
    manageExternalCRDs: false
    # IMPROVEMENT: Gateway resources if enabled
    resources:
      requests:
        memory: ${memory_request}
        cpu: ${cpu_request}
      limits:
        memory: ${memory_limit}
        cpu: ${cpu_limit}

# Controller for CRDs
controller:
  enabled: true
  # Optimized resources for Raspberry Pi controller
  resources:
    requests:
      memory: ${memory_request}
      cpu: ${cpu_request}
    limits:
      memory: ${memory_limit}
      cpu: ${cpu_limit}

  # # IMPROVEMENT: Add webhook configuration
  # webhook:
  #   tolerations:
  #     - effect: NoSchedule
  #       key: node-role.kubernetes.io/control-plane
  #       operator: Exists

# DNS configuration - DISABLED to avoid conflict with CoreDNS
dns:
  enabled: false
  type: ClusterIP
  # IMPROVEMENT: Add DNS-specific configuration
  clusterIP: null
  annotations: {}
  additionalSpec: {}

# IMPROVEMENT: Add sync catalog for Kubernetes service discovery - Optional, as requires the cluster to be formed and breaks deployment
syncCatalog:
  enabled: false
  default: true  # Opted-in all service to populate the consul service catalogue
  toConsul: true
  toK8S: false
  k8sAllowNamespaces: ["*"]
  k8sDenyNamespaces: ["kube-system", "kube-public", "default"]
  consulNamespaces:
    consulDestinationNamespace: "k8s-services"

  # Add resource limits
  resources:
    requests:
      memory: ${memory_request}
      cpu: ${cpu_request}
    limits:
      memory: ${memory_limit}
      cpu: ${cpu_limit}

# IMPROVEMENT: Add mesh gateway configuration (optional)
meshGateway:
  enabled: false
  replicas: 1
  service:
    type: ClusterIP
  resources:
    requests:
      memory: ${memory_request}
      cpu: ${cpu_request}
    limits:
      memory: ${memory_limit}
      cpu: ${cpu_limit}

# IMPROVEMENT: Add ingress gateway configuration (optional)
ingressGateways:
  enabled: false
  defaults:
    replicas: 1
    resources:
      requests:
        memory: ${memory_request}
        cpu: ${cpu_request}
      limits:
        memory: ${memory_limit}
        cpu: ${cpu_limit}

# IMPROVEMENT: Add terminating gateway configuration (optional)
terminatingGateways:
  enabled: false
  defaults:
    replicas: 1
    resources:
      requests:
        memory: ${memory_request}
        cpu: ${cpu_request}
      limits:
        memory: ${memory_limit}
        cpu: ${cpu_limit}

# IMPROVEMENT: Add Prometheus metrics configuration - DISABLED (use external Prometheus)
prometheus:
  enabled: false
