# Swimlane DevOps Practical

This repository dockerizes the Swimlane DevOps practical app and includes Kubernetes, Kustomize, and Terraform assets to deploy it with MongoDB.

## What is included

- `Dockerfile` for the Node.js application.
- `docker-compose.yml` for local app plus MongoDB validation.
- `k8s/base` and `k8s/overlays` for Kustomize deployment.
- `terraform/eks` for a multi-AZ Amazon EKS cluster.
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

## Local Kubernetes deployment

Use Docker Desktop Kubernetes or kind. If using kind:

```sh
kind create cluster --config kind/swimlane-cluster.yaml
```

Build and deploy:

```sh
./scripts/deploy-local.sh
```

HPA objects require the Kubernetes metrics API. Docker Desktop and kind do not always install metrics-server by default, so `kubectl get hpa` may show `<unknown>` metrics until metrics-server is installed.

Port-forward the app:

```sh
kubectl -n swimlane port-forward service/swimlane-app 3000:80
```

Open [http://localhost:3000](http://localhost:3000), register an account, and add a record.

Run a quick smoke test:

```sh
./scripts/smoke-test.sh
```

Clean up:

```sh
kubectl delete -k k8s/overlays/local
kind delete cluster --name swimlane
```

## EKS Terraform

The Terraform creates a VPC across three AZs, private worker-node subnets, one NAT gateway per AZ, EKS control-plane logging, IRSA, EBS CSI, and a three-node managed node group.

```sh
cd terraform/eks
terraform init
terraform plan
terraform apply
aws eks update-kubeconfig --region us-east-1 --name swimlane-practical
```

Build and push an image to your registry, then update `k8s/overlays/production/kustomization.yaml`:

```sh
docker build -t ghcr.io/<user>/swimlane-devops-practical:1.0.0 .
docker push ghcr.io/<user>/swimlane-devops-practical:1.0.0
kubectl apply -k k8s/overlays/production
```

For production, replace the demo MongoDB secret literals in `k8s/base/kustomization.yaml` or generate the Secret from your secret manager before applying.

## Operational checks

```sh
kubectl -n swimlane get pods -o wide
kubectl -n swimlane get hpa,pdb,svc
kubectl -n swimlane describe networkpolicy
kubectl -n swimlane logs deploy/swimlane-app
```

## Screenshot

After creating a record, save the screenshot under `docs/screenshots/`. The expected evidence is the running app showing the newly added article.
