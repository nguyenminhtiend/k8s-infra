apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${developer_base_role_arn}
      username: developer:{{SessionName}}
      groups:
      - system:masters
%{if create_readonly_role}- rolearn: ${developer_readonly_role_arn}
      username: readonly:{{SessionName}}
      groups:
      - readonly-users
%{endif}
  mapUsers: |
    []