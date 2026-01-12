#!/bin/bash
set -e

ENV="dev"
BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENV_DIR="$BASE_DIR/envs/$ENV"
MODULE_DIR="$BASE_DIR/modules/compute/ec2-ssm"

echo "🚀 Aplicando regla SG: frontend → backend (TCP 3000)"
echo "📍 Entorno: $ENV"

########################################
# 1️⃣ Variables del módulo
########################################

VAR_FILE="$MODULE_DIR/variables.tf"

if ! grep -q "frontend_security_group_id" "$VAR_FILE"; then
  echo "➕ Agregando variable frontend_security_group_id"

  cat <<EOF >> "$VAR_FILE"

variable "frontend_security_group_id" {
  description = "Security Group ID of the frontend EC2"
  type        = string
  default     = null
}
EOF
fi

########################################
# 2️⃣ Regla de Security Group
########################################

SG_RULE_FILE="$MODULE_DIR/sg_frontend_3000.tf"

if [ ! -f "$SG_RULE_FILE" ]; then
  echo "➕ Creando regla SG frontend → backend"

  cat <<EOF > "$SG_RULE_FILE"
resource "aws_security_group_rule" "allow_frontend_3000" {
  count = var.frontend_security_group_id == null ? 0 : 1

  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"

  security_group_id        = aws_security_group.this.id
  source_security_group_id = var.frontend_security_group_id

  description = "Allow TCP 3000 from frontend EC2"
}
EOF
fi

########################################
# 3️⃣ Output SG del frontend
########################################

OUT_FILE="$MODULE_DIR/outputs.tf"

if ! grep -q "security_group_id" "$OUT_FILE"; then
  echo "➕ Agregando output security_group_id"

  cat <<EOF >> "$OUT_FILE"

output "security_group_id" {
  value = aws_security_group.this.id
}
EOF
fi

########################################
# 4️⃣ Recordatorio wiring en env
########################################

echo
echo "⚠️ IMPORTANTE"
echo "Asegúrate que en envs/$ENV/main.tf el módulo privado tenga:"
echo
echo 'frontend_security_group_id = module.ec2_public_ssm.security_group_id'
echo

########################################
# 5️⃣ Terraform plan & apply
########################################

cd "$ENV_DIR"

terraform fmt -recursive
terraform init -reconfigure
terraform plan
terraform apply
