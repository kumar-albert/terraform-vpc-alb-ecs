resource "aws_lb_target_group" "grafana_tg" {
  name                 = lower("${var.environment}-${var.service_name}-tg")
  deregistration_delay = 15
  port                 = 3000
  protocol             = "HTTP"
  slow_start           = 0
  target_type          = "ip"
  vpc_id               = var.vpc_id
  health_check {
    enabled             = "true"
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = var.health_check_url
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
  tags = var.tags

}