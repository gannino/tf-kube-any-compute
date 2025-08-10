crds:
  enabled: true

master:
  resources:
    requests:
      cpu: 50m
      memory: 64Mi
    limits:
      cpu: 200m
      memory: 256Mi

worker:
  tolerations:
    - key: "node-role.kubernetes.io/control-plane"
      operator: "Exists"
      effect: "NoSchedule"
    - key: "node-role.kubernetes.io/master"
      operator: "Exists"
      effect: "NoSchedule"
  resources:
    requests:
      cpu: 25m
      memory: 32Mi
    limits:
      cpu: 100m
      memory: 128Mi
  config:
    sources:
      custom:
        - name: "rpi-model"
          matchOn:
            - loadedKMod: ["bcm2835_dma"]
          labels:
            rpi.feature/model: "true"
      cpu: {}
      kernel: {}           # ✅ MUST be a map
      memory: {}
      network: {}
      pci: {}               # ✅ MUST be a map (empty disables the source)
      usb: {}               # ✅ MUST be a map (empty is fine)
      sriov: false
      storage: {}
      system: {}
      baseboard: {}
      firmware: {}

gc:
  resources:
    requests:
      cpu: 10m
      memory: 32Mi
    limits:
      cpu: 50m
      memory: 128Mi

topologyUpdater:
  resources:
    requests:
      cpu: 25m
      memory: 32Mi
    limits:
      cpu: 100m
      memory: 128Mi
