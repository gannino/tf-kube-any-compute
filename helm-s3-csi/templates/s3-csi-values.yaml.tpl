# S3 CSI Driver Helm Values
# Based on Yandex Cloud k8s-csi-s3 driver

# S3 credentials secret configuration
secret:
  accessKeyID: "${secret.accessKeyID}"
  secretAccessKey: "${secret.secretAccessKey}"
  # Endpoint for S3-compatible storage
  endpoint: "${secret.endpoint}"
%{if secret.region != "" ~}
  # Region for AWS S3, Yandex Cloud (not used by QNAP, MinIO)
  region: "${secret.region}"
%{endif ~}

# CSI driver configuration
csiS3:
  # Mounter type: geesefs, rclone, or s3backer
  mounter: "${csiS3.mounter}"
  # Additional mounter options
  options: "${csiS3.options}"

# Storage class configuration
storageClass:
  # Name of the StorageClass
  name: "${storageClass.name}"
  # Existing S3 bucket to use (must already exist)
  bucket: "${storageClass.bucket}"
  # Reclaim policy: Retain or Delete
  reclaimPolicy: "${storageClass.reclaimPolicy}"
  # Volume binding mode: Immediate or WaitForFirstConsumer
  volumeBindingMode: "${storageClass.volumeBindingMode}"
  # Allow volume expansion
  allowVolumeExpansion: ${tostring(storageClass.allowVolumeExpansion)}
  # Set as default storage class
  isDefaultClass: ${tostring(storageClass.isDefaultClass)}

# Resource configuration
resources:
  limits:
    cpu: "${resources.limits.cpu}"
    memory: "${resources.limits.memory}"
  requests:
    cpu: "${resources.requests.cpu}"
    memory: "${resources.requests.memory}"

# Architecture configuration
arch: "${arch}"

# Node selector (if needed)
nodeSelector: {}

# Tolerations for CSI driver components
tolerations:
  controller: []
  node: []
  provisioner: []
