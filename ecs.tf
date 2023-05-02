resource "aws_ecs_cluster" "ecs_cluster" {
  name = lower("${var.environment}-ecs")
  tags = local.common_tags
}

module "grafana_service" {
  source = "./modules/ecs-service"
  environment = var.environment
  vpc_id = aws_vpc.main.id
  ecs_cluster_id = aws_ecs_cluster.ecs_cluster.id
  lb_security_group = aws_security_group.lb_sg.id
  subnet_ids = [for subnet in aws_subnet.private_subnet : subnet.id]
  service_name = "grafana"
  image_uri = "grafana/grafana"
  health_check_url = "/"
  tags = local.common_tags
}