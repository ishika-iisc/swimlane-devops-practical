#!/bin/bash
set -e

echo "=========================================="
echo "  Fix ECR Image Pull Issue"
echo "=========================================="

# Check if image has proper tags
echo -e "\n[1/5] Checking ECR images..."
aws ecr list-images --repository-name swimlane-practical-prod --region us-east-1

# Check node IAM role has ECR permissions
echo -e "\n[2/5] Checking node IAM role..."
NODE_ROLE=$(aws eks describe-nodegroup \
  --cluster-name swimlane-practical-prod \
  --nodegroup-name swimlane-practical-prod-general \
  --region us-east-1 \
  --query 'nodegroup.nodeRole' \
  --output text)

echo "Node IAM Role: $NODE_ROLE"

# Verify ECR permissions
echo -e "\n[3/5] Checking IAM policies attached..."
aws iam list-attached-role-policies --role-name $(basename $NODE_ROLE)

# Check if image manifest exists
echo -e "\n[4/5] Verifying latest tag exists..."
aws ecr describe-images \
  --repository-name swimlane-practical-prod \
  --image-ids imageTag=latest \
  --region us-east-1 2>&1 || echo "WARNING: 'latest' tag not found!"

# Monitor pods
echo -e "\n[5/5] Current pod status..."
kubectl -n swimlane get pods

echo -e "\n=========================================="
echo "If 'latest' tag is missing, run:"
echo "  docker tag <IMAGE_ID> 978355780214.dkr.ecr.us-east-1.amazonaws.com/swimlane-practical-prod:latest"
echo "  docker push 978355780214.dkr.ecr.us-east-1.amazonaws.com/swimlane-practical-prod:latest"
echo "=========================================="
