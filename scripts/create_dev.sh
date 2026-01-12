
#!/usr/bin/env bash

set -e

ENV="dev"
BASE_DIR="$(pwd)"
ENV_DIR="$BASE_DIR/envs/$ENV"

echo "🚀 Creando entorno Terraform: $ENV"

# 1. Crear directorio
mkdir -p "$ENV_DIR"

# 2. main.tf
cat <<EOF > "$ENV_DIR/main.tf"
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}
EOF

# 3. backend.tf
cat <<EOF > "$ENV_DIR/backend.tf"
terraform {
  backend "s3" {
    bucket         = "terraform-state-ignacio-587461243642"
    key            = "envs/dev/terraform.tfstate"
    region         = "us-west-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
EOF

# 4. variables.tf
cat <<EOF > "$ENV_DIR/variables.tf"
variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "aws_profile" {
  description = "AWS CLI profile"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}
EOF

# 5. terraform.tfvars
cat <<EOF > "$ENV_DIR/terraform.tfvars"
aws_region   = "us-west-1"
aws_profile = "terraform"
project_name = "ic-solutions"
environment  = "dev"
EOF

# 6. outputs.tf (placeholder)
cat <<EOF > "$ENV_DIR/outputs.tf"
output "environment" {
  value = var.environment
}
EOF

echo "✅ Entorno '$ENV' creado en envs/$ENV"
echo "👉 Siguiente paso:"
echo "   cd envs/dev"
echo "   terraform init"
