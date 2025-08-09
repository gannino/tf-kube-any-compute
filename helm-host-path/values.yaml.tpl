# Namespace configuration to prevent deployment in kube-system
namespace: ${namespace}

storageClass:
  defaultClass: ${set_as_default_storage_class}
  name: hostpath
  reclaimPolicy: Retain
  volumeBindingMode: WaitForFirstConsumer

resources:
  limits:
    cpu: ${cpu_limit}
    memory: ${memory_limit}
  requests:
    cpu: ${cpu_request}
    memory: ${memory_request}