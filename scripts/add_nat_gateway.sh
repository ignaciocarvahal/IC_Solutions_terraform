#!/bin/bash
set -e

VPC_MODULE_PATH="modules/networking/vpc"
MAIN_TF="$VPC_MODULE_PATH/main.tf"

echo "🚀 Agregando NAT Gateway al módulo VPC"

if [ ! -f "$MAIN_TF" ]; then
  echo "❌ No se encontró $MAIN_TF"
  exit 1
fi

echo "✍️ Inyectando recursos NAT en $MAIN_TF"

cat <<'EOF' >> $MAIN_TF

############################
# NAT Gateway (Private Out)
############################

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.name}-nat-eip"
  }
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "${var.name}-nat"
  }

  depends_on = [aws_internet_gateway.this]
}

############################
# Private Route Table
############################

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.name}-private-rt"
  }
}

resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

EOF

echo "✅ NAT Gateway agregado al módulo VPC"

echo "👉 Próximo paso:"
echo "   cd envs/dev"
echo "   terraform init -reconfigure"
echo "   terraform apply"
