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
