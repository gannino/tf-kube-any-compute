%{for node in nodes ~}
        - name: "${node.name}"
          directories:
          - path: /opt/local-path-provisioner/rook-storage
%{endfor ~}
