#!/bin/bash
set -e

MODULE_PATH="modules/networking/vpc"

echo "🚀 Creando módulo VPC en $MODULE_PATH"

mkdir -p $MODULE_PATH

#################################
# main.tf
#################################
cat <<EOF > $MODULE_PATH/main.tf
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = "\${var.name}-vpc"
  })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "\${var.name}-igw"
  })
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = var.az

  tags = merge(var.tags, {
    Name = "\${var.name}-public-subnet"
    Tier = "public"
  })
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.az

  tags = merge(var.tags, {
    Name = "\${var.name}-private-subnet"
    Tier = "private"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(var.tags, {
    Name = "\${var.name}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
EOF

#################################
# variables.tf
#################################
cat <<EOF > $MODULE_PATH/variables.tf
variable "name" {
  description = "Nombre base del stack"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR de la VPC"
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR subnet pública"
  type        = string
}

variable "private_subnet_cidr" {
  description = "CIDR subnet privada"
  type        = string
}

variable "az" {
  description = "Availability Zone"
  type        = string
}

variable "tags" {
  description = "Tags comunes"
  type        = map(string)
  default     = {}
}
EOF

#################################
# outputs.tf
#################################
cat <<EOF > $MODULE_PATH/outputs.tf
output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "private_subnet_id" {
  value = aws_subnet.private.id
}
EOF

echo "✅ Módulo VPC creado correctamente"
echo "👉 Siguiente paso:"
echo "   - Consumirlo desde envs/dev/main.tf"
