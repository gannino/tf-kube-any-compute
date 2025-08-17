global:
  enabled: true
  tlsDisable: true

injector:
  enabled: true
  image:
    repository: "hashicorp/vault-k8s"
    tag: "1.4.0"
  resources:
    requests:
      memory: 128Mi
      cpu: 100m
    limits:
      memory: 256Mi
      cpu: 200m

server:
  image:
    repository: "hashicorp/vault"
    tag: "1.18.0"
  resources:
    requests:
      cpu: ${cpu_request}
      memory: ${memory_request}
    limits:
      cpu: ${cpu_limit}
      memory: ${memory_limit}
  readinessProbe:
    enabled: true
    path: "/v1/sys/health?standbyok=true&sealedcode=204&uninitcode=204"
    initialDelaySeconds: 60
    timeoutSeconds: 10
    periodSeconds: 15
    failureThreshold: 5
  livenessProbe:
    enabled: true
    path: "/v1/sys/health?standbyok=true&sealedcode=204&uninitcode=204"
    initialDelaySeconds: 180
    timeoutSeconds: 10
    periodSeconds: 30
    failureThreshold: 6
  auditStorage:
    enabled: false
  standalone:
    enabled: false
  extraEnvironmentVars:
    VAULT_ADDR: "https://vault.${domain_name}"
    VAULT_API_ADDR: "https://vault.${domain_name}"
    VAULT_CLUSTER_ADDR: 'http://$(hostname).${name}-internal:8201'
    CONSUL_HTTP_ADD: "${consul_address}"
    VAULT_CONSUL_PATH: "vault/"
    GOMAXPROCS: "2"
    POD_IP:
      fieldRef:
        fieldPath: status.podIP

  # Init container removed - using separate Job for initialization

  volumes:
    - name: vault-scripts
      configMap:
        name: vault-scripts
        defaultMode: 0555
    - name: sa-token
      projected:
        sources:
          - serviceAccountToken:
              path: token
              expirationSeconds: 3607
          - configMap:
              name: kube-root-ca.crt
              items:
                - key: ca.crt
                  path: ca.crt
          - downwardAPI:
              items:
                - path: namespace
                  fieldRef:
                    fieldPath: metadata.namespace

  ha:
    enabled: true
    replicas: ${ha_replicas}
    config: |
      ui = true
      listener "tcp" {
        address = "[::]:8200"
        cluster_address = "[::]:8201"
        tls_disable = "true"
      }
      storage "consul" {
        address = "${consul_address}"
        path = "vault/"
        service = "vault"
        token = "${consul_token}"
      }
      service_registration "consul" {
        address = "${consul_address}"
        scheme  = "http"
        service = "vault"
        service_address = ""
        service_port = 8200
        session_ttl = "30s"           # Consul session TTL
        lock_wait_time = "15s"        # Lock acquisition timeout
        check_timeout = "10s"         # Health check timeout
        deregister_critical_service_after = "1m"  # Auto-cleanup
        token = "${consul_token}"
      }
      api_addr = "https://vault.${domain_name}"
      cluster_addr = "http://$(hostname).${name}-internal:8201"

  dataStorage:
    enabled: false

  service:
    enabled: true
    type: ClusterIP
    clusterIP: None
    selector:
      app.kubernetes.io/name: vault
    ports:
      - name: http
        port: 8200
        targetPort: 8200
      - name: cluster
        port: 8201
        targetPort: 8201
    annotations:
      consul.hashicorp.com/service-name: "vault"
      consul.hashicorp.com/service-tags: "vault,ha,web,api"
      consul.hashicorp.com/service-port: "8200"
      consul.hashicorp.com/service-check-http: "/v1/sys/health"
      consul.hashicorp.com/service-check-interval: "10s"
      consul.hashicorp.com/service-check-timeout: "5s"
ui:
  enabled: true
  serviceType: "ClusterIP"
  externalPort: 8200
