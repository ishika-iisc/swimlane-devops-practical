# Swimlane DevOps Practical

This repository dockerizes the Swimlane DevOps practical app and includes Terraform assets to create the Kubernetes infrastructure plus Kubernetes YAML/Kustomize manifests to deploy the app with MongoDB.

## What is included

- `Dockerfile` for the Node.js application.
- `docker-compose.yml` for local app plus MongoDB validation.
- `terraform/eks` for a multi-AZ Amazon EKS cluster and ECR repository using first-party AWS resources, not community modules.
- `k8s/base` and `k8s/overlays` for Kustomize-managed Kubernetes resources: app Deployment, MongoDB StatefulSet, Services, HPA, PDBs, NetworkPolicies, and optional Ingress.
- Optional `ansible` and `packer` examples for worker image preparation.
- `docs/architecture.md` with the cluster and high-availability notes.

The app is deployed as-is and only needs `MONGODB_URL`.

## Local Docker test

```sh
docker compose up --build
```

Open [http://localhost:3000](http://localhost:3000), register an account, and add a new article record.

Clean up:

```sh
docker compose down -v
```

## Local Kubernetes deployment with Kustomize

Use Docker Desktop Kubernetes or kind. If using kind:

```sh
kind create cluster --config kind/swimlane-cluster.yaml
```

Build the local image:

```sh
docker build -t swimlane-devops-practical:local .
```

Deploy the application and MongoDB with Kustomize:

```sh
kubectl apply -k k8s/overlays/local
kubectl -n swimlane rollout status statefulset/mongodb --timeout=180s
kubectl -n swimlane rollout status deployment/swimlane-app --timeout=180s
```

HPA objects require the Kubernetes metrics API. Docker Desktop and kind do not always install metrics-server by default, so `kubectl get hpa` may show `<unknown>` metrics until metrics-server is installed.

Port-forward the app:

```sh
kubectl -n swimlane port-forward service/swimlane-app 3000:80
```

Open [http://localhost:3000](http://localhost:3000), register an account, and add a record.

Run a quick smoke test:

```sh
cd ../..
./scripts/smoke-test.sh
```

Clean up:

```sh
kubectl delete -k k8s/overlays/local
kind delete cluster --name swimlane
```

## EKS with Terraform and app deployment with Kustomize

The Terraform creates a VPC across three AZs, private worker-node subnets, one NAT gateway per AZ, EKS control-plane logging, IRSA, EBS CSI, an ECR image repository, and a three-node managed node group. It uses explicit AWS resources instead of Terraform community modules.

```sh
cd terraform/eks
terraform init
terraform plan -var-file=prod.tfvars
terraform apply -var-file=prod.tfvars
aws eks update-kubeconfig --region us-east-1 --name swimlane-practical-prod
```

If you use a different IAM role or user to view the cluster in the AWS console or run `kubectl`, pass it in `cluster_admin_principal_arns` or `cluster_viewer_principal_arns` so Terraform creates the EKS access entry:

```sh
terraform apply \
  -var-file=prod.tfvars \
  -var='cluster_admin_principal_arns=["arn:aws:iam::<account-id>:role/<your-admin-role>"]'
```

Build and push the app image to the ECR repository created by Terraform:

```sh
export ECR_REPOSITORY_URL="$(terraform -chdir=terraform/eks output -raw ecr_repository_url)"
export IMAGE_TAG="$(git rev-parse --short HEAD)"
export IMAGE="${ECR_REPOSITORY_URL}:${IMAGE_TAG}"

aws ecr get-login-password --region us-east-1 \
  | docker login --username AWS --password-stdin "${ECR_REPOSITORY_URL%/*}"

docker buildx build --platform linux/amd64 -t "${IMAGE}" --push .
```

Update the production Kustomize overlay with your image and deploy the Kubernetes resources:

```sh
cd k8s/overlays/production
kustomize edit set image swimlane-devops-practical="${IMAGE}"
cd ../../..

kubectl apply -k k8s/overlays/production
```

For production, replace the demo MongoDB secret literals in `k8s/base/kustomization.yaml` or generate the Secret from your secret manager before applying.

## Helm scope

This repo currently deploys Kubernetes resources with Kustomize. A Helm chart could own the same Kubernetes app layer: Namespace, ConfigMaps, Secrets, ServiceAccount, app Deployment, app Service, HPA, PDBs, MongoDB StatefulSet and volume claim template, MongoDB Service, NetworkPolicies, and optional Ingress/TLS settings.

Terraform should continue to own AWS infrastructure: VPC, subnets, NAT gateways, EKS, IAM roles/policies, EKS access entries, IRSA, EBS CSI permissions, and ECR.

## Operational checks

```sh
kubectl -n swimlane get pods -o wide
kubectl -n swimlane get hpa,pdb,svc
kubectl -n swimlane describe networkpolicy
kubectl -n swimlane logs deploy/swimlane-app
```

## Screenshot

After creating a record, save the screenshot under `docs/screenshots/`. The expected evidence is the running app showing the newly added article.
