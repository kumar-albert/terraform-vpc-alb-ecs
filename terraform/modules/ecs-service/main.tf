resource "aws_ecs_task_definition" "grafana_definition" {
  family                   = lower("${var.environment}-${var.service_name}")
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  cpu                      = "2048"
  memory                   = "4096"
  requires_compatibilities = ["FARGATE"]
  tags                     = var.tags
  lifecycle {
    ignore_changes = [container_definitions]
  }
  container_definitions = <<TASK_DEFINITION
  [
    {
      "name": "${var.service_name}",
      "image": "${var.image_uri}",
      "essential": true,
      "logConfiguration": {
        "logDriver": "awslogs"
      },
      "portMappings": [
        {
          "containerPort": 3000,
          "hostPort": 3000,
          "protocol": "tcp"
        }
      ],
      "cpu": 1024,
      "memory": 2048,
      "environment": ${jsonencode(var.container_env)},
      "ulimits": [
        {
          "name": "nofile",
          "softLimit": 65536,
          "hardLimit": 65536
        }
      ],
      "mountPoints": [],
      "volumesFrom": []
    }
  ]
  TASK_DEFINITION
}


resource "aws_ecs_service" "grafana" {
  name                   = lower("${var.environment}-grafana-service-v1")
  cluster                = var.ecs_cluster_id
  task_definition        = aws_ecs_task_definition.grafana_definition.arn
  desired_count          = 1
  launch_type            = "FARGATE"
  enable_execute_command = true

  network_configuration {
    security_groups  = [aws_security_group.grafana_sg.id]
    subnets          = var.subnet_ids
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.grafana_tg.arn
    container_name   = lower("${var.environment}-grafana")
    container_port   = 3000
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
  depends_on = [
    aws_ecs_task_definition.grafana_definition,
  ]

  tags = var.tags
}

resource "aws_security_group" "grafana_sg" {
  name        = "${var.environment}-grafana-sg"
  description = "load balancer security group"
  vpc_id      = var.vpc_id
  ingress = [
    {
      description      = "Allow HTTP"
      protocol         = "tcp"
      from_port        = 3000
      to_port          = 3000
      cidr_blocks      = []
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = [var.lb_security_group]
      self             = false
    },
  ]

  egress {
    protocol    = "-1"
    description = "default egress"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

