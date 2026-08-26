resource "aws_security_group" "alb_sg" {
  name = "${var.name_prefix}-alb-sg"
  vpc_id = var.vpc_id

  ingress = {
    description = "HTTP from internet"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress = {
    description = "Allow outbound traffic"
    from_port = 0
    to_port = 0 
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-alb-sg"
    Service = "alb"
  })
}