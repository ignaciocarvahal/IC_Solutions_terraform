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

module "vpc" {
  source = "../../modules/networking/vpc"

  name                = "dev"
  vpc_cidr            = "10.0.0.0/16"
  public_subnet_cidr  = "10.0.1.0/24"
  private_subnet_cidr = "10.0.2.0/24"
  az                  = "us-west-1a"

  tags = {
    Environment = "dev"
    Project     = "IC_Solutions"
  }
}

###################################
# SG RULE: PUBLIC → PRIVATE :3000
###################################
resource "aws_security_group_rule" "allow_front_to_private_3000" {
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"

  security_group_id        = module.ec2_private_ssm.security_group_id
  source_security_group_id = module.ec2_public_ssm.security_group_id

  description = "Allow frontend (public EC2) to access backend on port 3000"
}

###################################
# SG RULES: INTERNET → FRONTEND
###################################

resource "aws_security_group_rule" "public_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]

  security_group_id = module.ec2_public_ssm.security_group_id
  description       = "Allow HTTP from Internet"
}

resource "aws_security_group_rule" "public_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]

  security_group_id = module.ec2_public_ssm.security_group_id
  description       = "Allow HTTPS from Internet"
}

###################################
# EC2 PUBLICA (SSM)
###################################
module "ec2_public_ssm" {
  source = "../../modules/compute/ec2-ssm"

  instance_name = "dev-public-ubuntu"
  ami_id        = "ami-0e4d9ed95865f3b40" # Ubuntu 22.04 us-west-1
  subnet_id     = module.vpc.public_subnet_id
  vpc_id        = module.vpc.vpc_id
  public_ip     = true

  user_data = <<EOF2
#!/bin/bash
snap install amazon-ssm-agent --classic
systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service
EOF2

  tags = {
    Environment = "dev"
    Project     = "IC_Solutions"
  }
}

###################################
# EC2 PRIVADA (SSM)
###################################
module "ec2_private_ssm" {
  source = "../../modules/compute/ec2-ssm"

  instance_name = "dev-private-ubuntu"
  ami_id        = "ami-0e4d9ed95865f3b40"
  subnet_id     = module.vpc.private_subnet_id
  vpc_id        = module.vpc.vpc_id
  public_ip     = false

  user_data = <<EOF2
#!/bin/bash
snap install amazon-ssm-agent --classic
systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service
EOF2

  tags = {
    Environment = "dev"
    Project     = "IC_Solutions"
  }
}
