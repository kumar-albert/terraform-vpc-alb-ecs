resource "aws_lb" "lb" {
  name               = "${var.environment}-lb"
  subnets            = [for subnet in aws_subnet.public_subnet : subnet.id]
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  internal           = false
  drop_invalid_header_fields = true

  tags = local.common_tags
}

resource "aws_security_group" "lb_sg" {
  name        = "${var.environment}-lb-sg"
  description = "load balancer security group"
  vpc_id      = aws_vpc.main.id
  ingress = [
    {
      description      = "Allow HTTP"
      protocol         = "tcp"
      from_port        = 80
      to_port          = 80
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
    {
      description      = "Allow HTTPS"
      protocol         = "tcp"
      from_port        = 443
      to_port          = 443
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  egress {
    protocol    = "-1"
    description = "default egress"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# resource "aws_lb_listener" "public" {
#   load_balancer_arn = aws_lb.lb.arn
#   port              = "443"
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
#   certificate_arn   = var.alb_certificate_arn

#   default_action {
#     type = "redirect"

#     redirect {
#       host        = var.domain
#       protocol    = "HTTPS"
#       port        = "443"
#       status_code = "HTTP_301"
#     }
#   }
# }



resource "aws_lb_listener" "http_forward" {
  load_balancer_arn = aws_lb.lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana_tg.arn
  }
}


resource "aws_lb_target_group" "grafana_tg" {
  name                 = lower("${var.environment}-grafana-tg")
  deregistration_delay = 15
  port                 = 3000
  protocol             = "HTTP"
  slow_start           = 0
  target_type          = "ip"
  vpc_id               = aws_vpc.main.id
  health_check {
    enabled             = "true"
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = 3000
    protocol            = "HTTP"
    timeout             = 29
    unhealthy_threshold = 5
  }
  stickiness {
    type            = "lb_cookie"
    cookie_duration = 300
    enabled         = false
  }
  tags = local.common_tags

}