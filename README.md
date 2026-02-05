# Terraform and AWS Configuration

A production-ready Terraform configuration for deploying infrastructure on AWS.

## Project Structure

- **provider.tf** - AWS provider configuration
- **main.tf** - Core infrastructure (VPC, Subnets, Internet Gateway, NAT Gateway)
- **variables.tf** - Input variables with validation
- **outputs.tf** - Output values
- **terraform.tfvars** - Variable values

## Prerequisites

1. **AWS Account** - Ensure you have an AWS account set up
2. **AWS Credentials** - Configure your AWS credentials:
   ```bash
   aws configure
   ```
   Or set environment variables:
   ```bash
   export AWS_ACCESS_KEY_ID=your_key
   export AWS_SECRET_ACCESS_KEY=your_secret
   export AWS_REGION=us-east-1
   ```

3. **Terraform** - Install Terraform (v1.0+):
   ```bash
   # macOS
   brew install terraform
   
   # Linux
   curl https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
   sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
   sudo apt-get update && sudo apt-get install terraform
   ```

## Quick Start

### 1. Initialize Terraform
```bash
terraform init
```

### 2. Customize Variables
Edit `terraform.tfvars` to match your requirements:
```hcl
environment = "dev"
project_name = "my-project"
aws_region = "us-east-1"
vpc_cidr = "10.0.0.0/16"
enable_nat_gateway = false
```

### 3. Plan Deployment
```bash
terraform plan
```

### 4. Apply Configuration
```bash
terraform apply
```

### 5. Destroy Resources (when done)
```bash
terraform destroy
```

## Features

### VPC Configuration
- 2 Public Subnets
- 2 Private Subnets
- Internet Gateway for public access
- NAT Gateway support (optional)
- Automatic availability zone distribution

### Best Practices Included
- Default tags for all resources
- Input validation
- Modular structure
- S3 backend configuration (commented, ready to enable)
- Proper state management setup

## Remote State Management (Optional)

To use S3 backend for storing Terraform state:

1. Create S3 bucket and DynamoDB table:
```bash
aws s3api create-bucket --bucket your-terraform-state-bucket --region us-east-1
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region us-east-1
```

2. Uncomment the backend configuration in `provider.tf`
3. Run `terraform init`

## Outputs

After deployment, retrieve outputs:
```bash
terraform output vpc_id
terraform output public_subnet_ids
terraform output private_subnet_ids
```

## Troubleshooting

- **Authentication errors**: Check AWS credentials with `aws sts get-caller-identity`
- **Region issues**: Verify AWS region in provider.tf matches your preference
- **State conflicts**: Delete `.terraform` directory and run `terraform init` again
- **Cost concerns**: Use `terraform plan` before `terraform apply` to review changes

## Additional Resources

- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices.html)
