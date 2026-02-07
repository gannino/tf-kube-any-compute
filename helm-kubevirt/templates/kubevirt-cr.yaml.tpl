apiVersion: kubevirt.io/v1
kind: KubeVirt
metadata:
  name: kubevirt
  namespace: ${namespace}
  annotations:
    # Allow deletion without webhook validation to prevent deadlock during cleanup
    kubevirt.io/deletion-validation: "bypass"
    # Allow updates without webhook validation to prevent connection refused errors
    kubevirt.io/update-validation: "bypass"
spec:
  certificateRotateStrategy: {}
  configuration:
    developerConfiguration:
      useEmulation: ${enable_emulation}
%{ if cpu_arch != "" ~}
    nodeSelectors:
      workloads:
        kubernetes.io/arch: ${cpu_arch}
%{ endif ~}
  customizeComponents: {}
  imagePullPolicy: IfNotPresent
  workloadUpdateStrategy: {}
