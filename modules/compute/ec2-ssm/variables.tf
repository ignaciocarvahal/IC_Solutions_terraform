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

variable "frontend_security_group_id" {
  description = "Security Group ID of the frontend EC2"
  type        = string
  default     = null
}
