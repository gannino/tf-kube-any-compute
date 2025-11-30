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
        # Disk attachment detection
        - name: "external-storage"
          matchOn:
            - pciId:
                vendor: ["1b21", "174c", "1f75"]  # Common USB/SATA controller vendors
          labels:
            storage.feature/external-controller: "true"
        # SD card detection (common on Pi)
        - name: "sd-card-storage"
          matchOn:
            - loadedKMod: ["mmc_block", "sdhci"]
          labels:
            storage.feature/sd-card: "true"
        # GPU detection
        - name: "gpu-present"
          matchOn:
            - pciId:
                class: ["0300", "0302"]  # VGA, 3D controllers
          labels:
            gpu.feature/present: "true"
        # Wireless capability
        - name: "wireless-capability"
          matchOn:
            - loadedKMod: ["cfg80211", "mac80211"]
          labels:
            network.feature/wireless: "true"
        # Docker/containerd runtime
        - name: "container-runtime"
          matchOn:
            - loadedKMod: ["overlay", "br_netfilter"]
          labels:
            runtime.feature/container-ready: "true"
      cpu: {}
      kernel:
        # Enable kernel feature detection
        kconfigFile: "/proc/config.gz"
        configOpts: ["NO_HZ", "PREEMPT", "CGROUPS", "NAMESPACES"]
      memory:
        # Enable memory feature detection
        numa: true
        nv: true  # Non-volatile memory detection
      network:
        # Enable network interface detection
        sources: ["sriov", "device"]
        deviceLabelFields: ["operstate", "speed"]
      pci:
        # Enable PCI device detection for hardware identification
        deviceClassWhitelist: ["02", "03", "0c"]  # Network, Display, Serial controllers
        deviceLabelFields: ["vendor", "device", "class"]
      usb:
        # Enable USB device detection
        deviceClassWhitelist: ["02", "03", "08", "09", "0e"]  # Network, HID, Mass Storage, Hub, Video
        deviceLabelFields: ["vendor", "product", "class"]
      sriov:
        # Enable SR-IOV detection for advanced networking
        enable: true
      storage:
        # Enable storage device detection
        # Detects block devices, filesystems, and storage controllers
        blockDeviceSelector:
          # Detect all block devices
          matchAny:
            - "true"
        # Custom rules for specific storage types
        rules:
          # NVMe drives
          - name: "nvme-drive"
            labels:
              storage.feature/nvme: "true"
            matchFeatures:
              - feature: storage.block
                matchExpressions:
                  - key: "name"
                    operator: In
                    values: ["nvme*"]
          # SATA/SCSI drives
          - name: "sata-drive"
            labels:
              storage.feature/sata: "true"
            matchFeatures:
              - feature: storage.block
                matchExpressions:
                  - key: "name"
                    operator: In
                    values: ["sd*"]
          # USB storage
          - name: "usb-storage"
            labels:
              storage.feature/usb: "true"
            matchFeatures:
              - feature: storage.block
                matchExpressions:
                  - key: "subsystems"
                    operator: In
                    values: ["usb"]
          # High-capacity storage (>1TB)
          - name: "high-capacity-storage"
            labels:
              storage.feature/high-capacity: "true"
            matchFeatures:
              - feature: storage.block
                matchExpressions:
                  - key: "size"
                    operator: Gt
                    values: ["1000000000000"]  # 1TB in bytes
      system:
        # Enable system information detection
        osRelease: ["ID", "VERSION_ID", "VARIANT_ID"]
        dmiId: ["bios_vendor", "bios_version", "sys_vendor", "product_name"]
      baseboard:
        # Enable baseboard/motherboard detection
        dmiId: ["board_vendor", "board_name", "board_version"]
      firmware:
        # Enable firmware detection
        dmiId: ["bios_vendor", "bios_version", "bios_date"]
        sysfs: ["/sys/firmware/efi", "/sys/firmware/devicetree"]

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
