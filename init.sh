#!/bin/bash
set -e

echo "🚀 Initializing Terraform..."
terraform init

echo "📋 Planning deployment..."
terraform plan -out=tfplan

echo "✅ Plan saved to tfplan"
echo "📝 Review the plan above, then run: terraform apply tfplan"
