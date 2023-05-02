resource "aws_ecs_cluster" "ecs_cluster" {
  name = lower("${var.environment}-ecs")
  tags = local.common_tags
}

resource "aws_ecs_task_definition" "grafana_definition" {
  family                   = lower("${var.environment}-grafana")
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  cpu                      = "2048"
  memory                   = "4096"
  requires_compatibilities = ["FARGATE"]
  tags                     = local.common_tags
  lifecycle {
    ignore_changes = [container_definitions]
  }
  container_definitions = <<TASK_DEFINITION
  [
    {
      "name": "grafana",
      "image": "grafana/grafana",
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
      "environment": [
      ],
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
  cluster                = aws_ecs_cluster.ecs_cluster.id
  task_definition        = aws_ecs_task_definition.grafana_definition.arn
  desired_count          = 1
  launch_type            = "FARGATE"
  enable_execute_command = true

  network_configuration {
    security_groups  = [aws_security_group.grafana_sg.id]
    subnets          = [for subnet in aws_subnet.private_subnet : subnet.id]
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

  tags = local.common_tags
}

resource "aws_security_group" "grafana_sg" {
  name        = "${var.environment}-grafana-sg"
  description = "load balancer security group"
  vpc_id      = aws_vpc.main.id
  ingress = [
    {
      description      = "Allow HTTP"
      protocol         = "tcp"
      from_port        = 3000
      to_port          = 3000
      cidr_blocks      = []
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = [aws_security_group.lb_sg.id]
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