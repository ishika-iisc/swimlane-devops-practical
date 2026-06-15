# Helm Scope

The current implementation uses Kustomize for the Kubernetes deployment. Helm would be an equivalent packaging option for the Kubernetes application layer, not for the AWS infrastructure layer.

## Good Helm Candidates

- `Namespace` for the application.
- Application `ConfigMap` and generated/runtime `Secret` references.
- Application `ServiceAccount`.
- Application `Deployment`, including replicas, probes, security context, resources, topology spread, and pod anti-affinity.
- Application `Service`.
- Application `HorizontalPodAutoscaler`.
- Application `PodDisruptionBudget`.
- MongoDB init `ConfigMap`.
- MongoDB credentials `Secret`.
- MongoDB `StatefulSet`, including the persistent volume claim template.
- MongoDB `Service`.
- MongoDB `PodDisruptionBudget`.
- `NetworkPolicy` resources.
- Optional production `Ingress` and TLS secret references.

## Keep In Terraform

- VPC, subnets, routes, NAT gateways, and internet gateway.
- EKS cluster and managed node group.
- IAM roles, IAM policy attachments, EKS access entries, and IRSA.
- EKS add-ons and EBS CSI IAM permissions.
- ECR repository, image scanning, encryption, and lifecycle policy.

For this practical, Kustomize is kept because the manifests are small, explicit, and easy to review. Helm would be useful if the deployment needed repeated installs with different values across environments.
