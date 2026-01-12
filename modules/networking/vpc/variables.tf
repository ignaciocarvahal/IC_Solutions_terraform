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

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnet outbound traffic"
  type        = bool
  default     = true
}
