#!/bin/bash
set -e

echo "🛠️ Corrigiendo módulo ec2-ssm (Security Groups + Outputs)"

MODULE_PATH="modules/compute/ec2-ssm"

mkdir -p $MODULE_PATH

###################################
# VARIABLES
###################################
cat > $MODULE_PATH/variables.tf <<'EOF'
variable "instance_name" {}
variable "ami_id" {}
variable "subnet_id" {}
variable "vpc_id" {}
variable "public_ip" {
  type    = bool
  default = false
}
variable "user_data" {
  type    = string
  default = ""
}
variable "tags" {
  type    = map(string)
  default = {}
}

variable "allowed_sg_id" {
  type        = string
  default     = null
  description = "Security Group allowed to access port 3000"
}
EOF

###################################
# SECURITY GROUP
###################################
cat > $MODULE_PATH/security_group.tf <<'EOF'
resource "aws_security_group" "this" {
  name        = "${var.instance_name}-sg"
  description = "SG for ${var.instance_name}"
  vpc_id      = var.vpc_id

  # SSM outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

# Allow port 3000 ONLY from frontend SG
resource "aws_security_group_rule" "allow_3000_from_frontend" {
  count                    = var.allowed_sg_id == null ? 0 : 1
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.this.id
  source_security_group_id = var.allowed_sg_id
}
EOF

###################################
# EC2
###################################
cat > $MODULE_PATH/main.tf <<'EOF'
resource "aws_instance" "this" {
  ami                         = var.ami_id
  instance_type               = "t3.micro"
  subnet_id                   = var.subnet_id
  associate_public_ip_address = var.public_ip
  vpc_security_group_ids      = [aws_security_group.this.id]
  user_data                   = var.user_data

  tags = merge(
    {
      Name = var.instance_name
    },
    var.tags
  )
}
EOF

###################################
# OUTPUTS
###################################
cat > $MODULE_PATH/outputs.tf <<'EOF'
output "instance_id" {
  value = aws_instance.this.id
}

output "security_group_id" {
  value = aws_security_group.this.id
}
EOF

echo "✅ Módulo ec2-ssm corregido correctamente"
echo "👉 Ahora conecta los SGs desde envs/dev"
