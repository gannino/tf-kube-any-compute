apiVersion: v1
kind: ServiceAccount
metadata:
  name: kubevirt-operator
  namespace: ${namespace}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: kubevirt-operator
rules:
  - apiGroups: [""]
    resources: ["*"]
    verbs: ["*"]
  - apiGroups: ["apps"]
    resources: ["*"]
    verbs: ["*"]
  - apiGroups: ["kubevirt.io"]
    resources: ["*"]
    verbs: ["*"]
  - apiGroups: ["apiextensions.k8s.io"]
    resources: ["customresourcedefinitions"]
    verbs: ["*"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: kubevirt-operator
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: kubevirt-operator
subjects:
  - kind: ServiceAccount
    name: kubevirt-operator
    namespace: ${namespace}
