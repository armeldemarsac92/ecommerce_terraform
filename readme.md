# API Infrastructure as Code

This repository contains Terraform configuration for deploying a complete API infrastructure on AWS. The infrastructure includes a VPC, load balancer, ECS services for frontend, API, and authentication, along with a PostgreSQL database and bastion host for secure access.

## Architecture Overview

The infrastructure setup consists of the following components:

- **VPC**: A Virtual Private Cloud with both public and private subnets across 3 availability zones in the eu-central-1 region, complete with IPv6 support
- **Load Balancer**: An Application Load Balancer routing traffic to different services based on domain names
- **ECS Cluster**: Running containerized services for:
    - Frontend application
    - API server
    - Authentication server
- **Database**: RDS PostgreSQL instance for data storage
- **Bastion Host**: EC2 instance for secure SSH access to resources in private subnets
- **DNS**: Route53 configuration for domain management

## Repository Structure

```
.
├── .gitignore                         # Git ignore file
├── .gitlab-ci.yml                     # GitLab CI/CD pipeline configuration
├── backend.tf                         # Terraform backend configuration
├── main.tf                            # Main Terraform configuration
├── variables.tf                       # Variable definitions
├── modules/                           # Terraform modules
│   ├── bastion/                       # EC2 bastion host configuration
│   ├── database/                      # RDS database configuration
│   ├── ecs/                           # ECS cluster and services
│   ├── load_balancer/                 # Application Load Balancer
│   ├── vpc/                           # VPC, subnets, and networking
├── terraform-backend/                 # S3 and DynamoDB for Terraform state
```

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) v1.7.4 or newer
- AWS CLI configured with appropriate credentials
- S3 bucket and DynamoDB table for Terraform state (see terraform-backend directory)

## Getting Started

### Setting Up Remote State

Before deploying the main infrastructure, you need to set up the remote state backend:

```bash
cd terraform-backend
terraform init
terraform apply
```

This will create:
- An S3 bucket for storing Terraform state
- A DynamoDB table for state locking

Take note of the outputs, as you'll need them for GitLab CI/CD variables.

### Local Development

1. Initialize Terraform with the remote backend:

```bash
terraform init \
  -backend-config="bucket=tdev700-terraform-state" \
  -backend-config="key=tdev700/dev.tfstate" \
  -backend-config="region=eu-central-1" \
  -backend-config="dynamodb_table=terraform-state-locks" \
  -backend-config="encrypt=true"
```

2. Create a terraform plan:

```bash
terraform plan -out=tfplan
```

3. Apply the plan:

```bash
terraform apply tfplan
```

## GitLab CI/CD Pipeline

The repository includes a GitLab CI/CD pipeline configured in `.gitlab-ci.yml` that automates the deployment process:

- **terraform:validate**: Runs on the main branch to validate Terraform configuration
- **terraform:plan**: Creates and displays a plan for what changes would be made
- **terraform:apply**: Applies the Terraform plan (manual trigger required)
- **terraform:destroy**: Destroys the infrastructure (manual trigger required)

### Required CI/CD Variables

The following environment variables must be set in the GitLab project settings:

- `AWS_ACCESS_KEY_ID`: AWS access key
- `AWS_SECRET_ACCESS_KEY`: AWS secret key
- `AWS_REGION`: AWS region (eu-central-1)
- `TF_STATE_BUCKET`: S3 bucket name for Terraform state
- `TF_LOCK_TABLE`: DynamoDB table name for state locking

## Component Details

### VPC Module

- CIDR block: 172.30.0.0/16
- 3 public subnets across different availability zones
- 3 private subnets across different availability zones
- Internet Gateway for public subnet access
- IPv6 support

### Database Module

- PostgreSQL RDS instance
- Uses snapshots for backup and recovery
- Hosted in private subnets
- Private DNS record for service discovery

### Load Balancer Module

- Application Load Balancer with SSL
- Host-based routing to direct traffic to appropriate services
- Supports IPv4 and IPv6 (dualstack)

### ECS Module

- Fargate for serverless container management
- Services for API, Auth, and Frontend applications
- AWS CloudWatch logs integration
- Health checks for all services

### Bastion Module

- t2.nano EC2 instance
- Public access restricted to SSH (port 22)
- Secure access to database and other private resources

## Security Considerations

- Database is in private subnets, inaccessible from the internet
- Bastion host for secure SSH access to private resources
- Security groups restrict traffic between services
- HTTPS-only for public-facing services
- AWS ACM certificate for SSL

## DNS Configuration

The infrastructure is set up for the following domains:

- epitechproject.fr (main domain for frontend)
- api.epitechproject.fr (API service)
- auth.epitechproject.fr (Authentication service)

## Backup and Recovery

- Database uses snapshots for backup
- Final snapshot is created when the database is destroyed

## Contribution Guidelines

1. Create a feature branch from main
2. Make your changes
3. Submit a merge request
4. Wait for the CI/CD pipeline to validate your changes
5. Request a review

## Known Issues and Limitations

- Hard-coded AMI ID in the bastion module may need to be updated for different regions
- The infrastructure assumes the existence of certain IAM roles and ECR repositories
