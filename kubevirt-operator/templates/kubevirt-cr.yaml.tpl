apiVersion: kubevirt.io/v1
kind: KubeVirt
metadata:
  name: kubevirt
  namespace: ${namespace}
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
