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

resource "aws_lb" "alb" {
  name = "${var.name_prefix}-alb"
  internal = false
  load_balancer_type = "application"

  security_groups = [
    aws_security_group.alb_sg.id
  ]

  subnets = var.public_subnet_ids

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-alb"
    Service = "alb"
  })
}

resource "aws_lb_target_group" "api" {
  name = "${var.name_prefix}-api-tg"
  port = 8080
  protocol = "HTTP"
  vpc_id = var.vpc_id
  target_type = "ip"

  health_check {
    enabled = true
    path = "/healthz"
    protocol = "HTTP"
    port = "traffic-port"
    healthy_threshold = 2
    unhealthy_threshold = 3
    timeout = 5
    interval = 30
    matcher = "200"
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-api-tg"
    Service = "api"
  })
}

resource "aws_lb_target_group" "dashboard" {
  name = "${var.name_prefix}-dashboard-tg"
  port = 8081
  protocol = "HTTP"
  vpc_id = var.vpc_id
  target_type = "ip"

  health_check {
    enabled = true
    path = "/healthz"
    protocol = "HTTP"
    port = "traffic-port"
    healthy_threshold = 2
    unhealthy_threshold = 3
    timeout = 5
    interval = 30
    matcher = "200"
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-dashboard-tg"
    Service = "dashboard"
  })
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn

  port = 80
  protocol = "HTTP"

  default_action {
    type = "redirect"
    
    redirect {
      port = "443"
      protocol = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.alb.arn

  port = 443
  protocol = "HTTPS"

  certificate_arn = var.certificate_arn
  ssl_policy = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
}

resource "aws_lb_listener_rule" "listener_rule" {
  listener_arn = aws_lb_listener.https.arn
  priority = 100

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.dashboard.arn
  }

  condition {
    path_pattern {
      values = [
        "/summary",
        "/recent",
        "/top",
        "/url/*"
      ]
    }
  }
}