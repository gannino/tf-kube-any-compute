apiVersion: apps/v1
kind: Deployment
metadata:
  name: virt-operator
  namespace: ${namespace}
spec:
  replicas: 2
  selector:
    matchLabels:
      kubevirt.io: virt-operator
  template:
    metadata:
      labels:
        kubevirt.io: virt-operator
    spec:
      serviceAccountName: kubevirt-operator
%{ if cpu_arch != "" ~}
      nodeSelector:
        kubernetes.io/arch: ${cpu_arch}
%{ endif ~}
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: kubernetes.io/hostname
          whenUnsatisfiable: ScheduleAnyway
          labelSelector:
            matchLabels:
              kubevirt.io: virt-operator
      containers:
        - name: virt-operator
          image: quay.io/kubevirt/virt-operator:${kubevirt_version}
          imagePullPolicy: IfNotPresent
          resources:
            requests:
              cpu: ${cpu_request}
              memory: ${memory_request}
            limits:
              cpu: ${cpu_limit}
              memory: ${memory_limit}
          env:
            - name: OPERATOR_IMAGE
              value: quay.io/kubevirt/virt-operator:${kubevirt_version}
