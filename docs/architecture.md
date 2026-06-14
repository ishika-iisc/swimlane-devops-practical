# Architecture Notes

## Cluster

The production path uses Amazon EKS from `terraform/eks`. It creates:

- A VPC spread across three availability zones.
- Public subnets for load balancers and private subnets for worker nodes.
- One NAT gateway per AZ to avoid a single NAT dependency.
- An EKS control plane with audit/control-plane logs enabled.
- A managed node group with three desired nodes across private subnets.
- EKS add-ons for CoreDNS, kube-proxy, VPC CNI, and EBS CSI.

For a laptop demo, `kind/swimlane-cluster.yaml` defines a local three-node kind cluster. Docker Desktop Kubernetes also works with the same Terraform application stack.

## Application

The app is deployed by `terraform/app` as two pods behind a ClusterIP service. Kubernetes uses `/healthz` for readiness and liveness. The deployment includes resource requests/limits, a rolling update strategy, HPA, PDB, pod anti-affinity, and topology spread constraints.

## MongoDB

MongoDB is deployed by Terraform as a containerized StatefulSet with a persistent volume and an app-scoped database user. For a true production data tier I would use MongoDB Atlas, DocumentDB, or a MongoDB operator-managed replica set. The included StatefulSet keeps the practical self-contained while the Terraform cluster and web tier remove the main cluster/application single points of failure.

## Security

- The app container runs as a non-root user with token automount disabled.
- Kubernetes stores MongoDB credentials in a Secret managed by Terraform.
- NetworkPolicy limits MongoDB traffic to the app pods and limits app egress to DNS plus MongoDB.
- `terraform/app` enables `NODE_ENV=production` by default and can create a TLS Ingress.
- Terraform enables EKS control-plane logs and IRSA.

Replace the demo secret values before using this outside a local practical.
