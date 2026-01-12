#!/bin/bash
set -e

echo "🚀 Creando módulo EC2 Ubuntu con SSM"

BASE_DIR="$(pwd)"

MODULE_DIR="modules/compute/ec2-ssm"
ENV_DIR="envs/dev"

mkdir -p $MODULE_DIR

###################################
# variables.tf
###################################
cat > $MODULE_DIR/variables.tf <<'EOF'
variable "instance_name" { type = string }
variable "ami_id" { type = string }
variable "subnet_id" { type = string }
variable "vpc_id" { type = string }
variable "public_ip" { type = bool }
variable "tags" { type = map(string) }

variable "user_data" {
  type    = string
  default = ""
}
EOF

###################################
# main.tf
###################################
cat > $MODULE_DIR/main.tf <<'EOF'
resource "aws_iam_role" "ssm_role" {
  name = "${var.instance_name}-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.instance_name}-profile"
  role = aws_iam_role.ssm_role.name
}

resource "aws_security_group" "this" {
  name   = "${var.instance_name}-sg"
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_instance" "this" {
  ami                    = var.ami_id
  instance_type          = "t3.micro"
  subnet_id              = var.subnet_id
  associate_public_ip_address = var.public_ip

  vpc_security_group_ids = [aws_security_group.this.id]
  iam_instance_profile   = aws_iam_instance_profile.this.name
  user_data              = var.user_data

  tags = merge(var.tags, {
    Name   = var.instance_name
    Access = "SSM"
  })
}
EOF

###################################
# outputs.tf
###################################
cat > $MODULE_DIR/outputs.tf <<'EOF'
output "instance_id" {
  value = aws_instance.this.id
}
EOF

echo "✅ Módulo EC2 SSM creado"

###################################
# Actualizar envs/dev/main.tf
###################################
cat >> $ENV_DIR/main.tf <<'EOF'

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
EOF

echo "🎯 EC2 públicas y privadas agregadas al entorno dev"
echo "👉 Siguiente paso:"
echo "   cd envs/dev"
echo "   terraform init"
echo "   terraform plan"
echo "   terraform apply"
