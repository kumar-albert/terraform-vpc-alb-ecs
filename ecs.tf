locals {
    grafana_container_env = {
        GF_DATABASE_HOST = aws_db_instance.main.endpoint
    }
}

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
  container_env = [
    { "name": "GF_DATABASE_HOST", "value": aws_db_instance.main.endpoint },
    { "name": "GF_DATABASE_NAME", "value": "grafana" },
    { "name": "GF_DATABASE_USER", "value": local.db_username },
    { "name": "GF_DATABASE_PASSWORD", "value": random_password.db_master_pass.result },
    { "name": "GF_DATABASE_TYPE", "value": "mysql" },
    { "name": "GF_DATABASE_MAX_OPEN_CONN", "value": 50 },
  ]
  tags = local.common_tags
}