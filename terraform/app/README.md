# Terraform Application Deployment

This stack deploys the Swimlane application and MongoDB into an existing
Kubernetes cluster using Terraform and the Kubernetes provider.

## Local cluster

Build the app image first:

```sh
docker build -t swimlane-devops-practical:local ../..
```

Then apply the Kubernetes resources:

```sh
# If you are not using kind-swimlane, edit kube_context in local.tfvars.example.
terraform init
terraform apply -var-file=local.tfvars.example
```

Open the app:

```sh
kubectl -n swimlane port-forward service/swimlane-app 3000:80
```

## EKS

Create the cluster first:

```sh
cd ../eks
terraform init
terraform apply
aws eks update-kubeconfig --region us-east-1 --name swimlane-practical
```

Build and push the app image, then deploy:

```sh
cd ../app
cp production.tfvars.example production.tfvars
# edit production.tfvars
terraform init
terraform apply -var-file=production.tfvars
```

The Terraform state will contain Kubernetes Secret values. Use an encrypted
remote backend for any non-demo deployment.
