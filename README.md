# Swimlane DevOps Practical

This repository dockerizes the Swimlane DevOps practical app and includes Terraform assets to create the Kubernetes infrastructure and deploy the app with MongoDB.

## What is included

- `Dockerfile` for the Node.js application.
- `docker-compose.yml` for local app plus MongoDB validation.
- `terraform/eks` for a multi-AZ Amazon EKS cluster.
- `terraform/app` for Terraform-managed Kubernetes resources: app Deployment, MongoDB StatefulSet, Services, HPA, PDBs, NetworkPolicies, and optional Ingress.
- `k8s/base` and `k8s/overlays` as Kustomize reference manifests.
- Optional `ansible` and `packer` examples for worker image preparation.
- `docs/architecture.md` with the cluster and high-availability notes.

The upstream app only requires `MONGODB_URL`. I added `/healthz` so Kubernetes can probe the app cleanly.

## Local Docker test

```sh
docker compose up --build
```

Open [http://localhost:3000](http://localhost:3000), register an account, and add a new article record.

Clean up:

```sh
docker compose down -v
```

## Local Kubernetes deployment with Terraform

Use Docker Desktop Kubernetes or kind. If using kind:

```sh
kind create cluster --config kind/swimlane-cluster.yaml
```

Build the local image:

```sh
docker build -t swimlane-devops-practical:local .
```

Deploy the application and MongoDB with Terraform:

```sh
cd terraform/app
# If you are not using the kind cluster above, edit kube_context in local.tfvars.example.
terraform init
terraform apply \
  -var-file=local.tfvars.example
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
cd terraform/app
terraform destroy -var-file=local.tfvars.example
kind delete cluster --name swimlane
```

## EKS and app deployment with Terraform

The Terraform creates a VPC across three AZs, private worker-node subnets, one NAT gateway per AZ, EKS control-plane logging, IRSA, EBS CSI, and a three-node managed node group.

```sh
cd terraform/eks
terraform init
terraform plan
terraform apply
aws eks update-kubeconfig --region us-east-1 --name swimlane-practical
```

Build and push an image to your registry:

```sh
docker build -t ghcr.io/<user>/swimlane-devops-practical:1.0.0 .
docker push ghcr.io/<user>/swimlane-devops-practical:1.0.0
```

Deploy the Kubernetes resources with Terraform:

```sh
cd terraform/app
cp production.tfvars.example production.tfvars
# Edit production.tfvars: image, passwords, host, TLS secret.
terraform init
terraform plan -var-file=production.tfvars
terraform apply -var-file=production.tfvars
```

For production, replace the demo MongoDB password values in `production.tfvars`. Terraform state will contain Kubernetes Secret values, so use an encrypted remote backend for any non-demo deployment.

## Operational checks

```sh
kubectl -n swimlane get pods -o wide
kubectl -n swimlane get hpa,pdb,svc
kubectl -n swimlane describe networkpolicy
kubectl -n swimlane logs deploy/swimlane-app
```

## Screenshot

After creating a record, save the screenshot under `docs/screenshots/`. The expected evidence is the running app showing the newly added article.
