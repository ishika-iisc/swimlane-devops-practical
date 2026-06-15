#!/bin/bash
set -e

echo "=========================================="
echo "  Swimlane App - EKS Deployment Script"
echo "=========================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check prerequisites
echo -e "\n${YELLOW}[1/8] Checking prerequisites...${NC}"
command -v kubectl >/dev/null 2>&1 || { echo -e "${RED}kubectl not found${NC}"; exit 1; }
command -v docker >/dev/null 2>&1 || { echo -e "${RED}docker not found${NC}"; exit 1; }
command -v terraform >/dev/null 2>&1 || { echo -e "${RED}terraform not found${NC}"; exit 1; }

# Get ECR repository URL
echo -e "\n${YELLOW}[2/8] Getting ECR repository URL...${NC}"
export ECR_REPOSITORY_URL=$(terraform -chdir=terraform/eks output -raw ecr_repository_url)
echo "ECR Repository: $ECR_REPOSITORY_URL"

# Update Kustomize with ECR image
echo -e "\n${YELLOW}[3/8] Updating Kustomize configuration...${NC}"
sed -i.bak "s|newName:.*|newName: $ECR_REPOSITORY_URL|g" k8s/overlays/production/kustomization.yaml
sed -i.bak "s|newTag:.*|newTag: latest|g" k8s/overlays/production/kustomization.yaml
echo -e "${GREEN}✓ Kustomize updated${NC}"

# Verify cluster connectivity
echo -e "\n${YELLOW}[4/8] Verifying EKS cluster connectivity...${NC}"
kubectl cluster-info
kubectl get nodes

# Deploy to EKS
echo -e "\n${YELLOW}[5/8] Deploying application and MongoDB to EKS...${NC}"
kubectl apply -k k8s/overlays/production

# Wait for MongoDB
echo -e "\n${YELLOW}[6/8] Waiting for MongoDB to be ready...${NC}"
kubectl -n swimlane rollout status statefulset/mongodb --timeout=300s

# Wait for App
echo -e "\n${YELLOW}[7/8] Waiting for Swimlane app to be ready...${NC}"
kubectl -n swimlane rollout status deployment/swimlane-app --timeout=300s

# Show deployment status
echo -e "\n${YELLOW}[8/8] Deployment Summary${NC}"
echo "=========================================="
kubectl -n swimlane get pods -o wide
echo ""
kubectl -n swimlane get svc,hpa,pdb

echo -e "\n${GREEN}=========================================="
echo "  ✓ Deployment Complete!"
echo "==========================================${NC}"
echo ""
echo "To access the application:"
echo "  kubectl -n swimlane port-forward service/swimlane-app 3000:80"
echo ""
echo "Then open: http://localhost:3000"
echo ""
echo "To check logs:"
echo "  kubectl -n swimlane logs deploy/swimlane-app -f"
