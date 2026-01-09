
# IC_Solutions_terraform
infraestructura de IC Solutions

# Terraform AWS Infrastructure

Repositorio de infraestructura como código usando Terraform.

## Estructura
- modules/: módulos reutilizables
- envs/: definición por entorno (dev, staging, prod)
- global/: recursos globales (IAM, Route53)
- backend/: backend remoto (S3 + DynamoDB)

## Reglas
- No usar recursos directos en envs sin módulos
- Un backend por entorno
- State remoto obligatorio
