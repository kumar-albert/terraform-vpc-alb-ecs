resource "aws_db_subnet_group" "db_private_subnet_group" {
  name       = lower("${var.environment}-db-sng")
  subnet_ids = [for subnet in aws_subnet.private_subnet : subnet.id]

  tags = local.common_tags
}

resource "aws_db_parameter_group" "main_db_pg" {
  name   = lower("${var.environment}-mysql-db-pg")
  family = "mysql8.0"

  tags = local.common_tags

}


resource "random_password" "db_master_pass" {
  length           = 20
  special          = true
  min_special      = 5
  override_special = "!#$%^&*()-_=+[]{}<>:?"
  keepers = {
    pass_version = 1
  }
}

resource "aws_secretsmanager_secret" "db-pass" {
  name = "db-password-${var.environment}"
  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "db-pass-val" {
  secret_id     = aws_secretsmanager_secret.db-pass.id
  secret_string = random_password.db_master_pass.result
}


resource "aws_db_instance" "main" {
  engine                          = "mysql"
  engine_version                  = "8.0.27"
  instance_class                  = "db.t2.small"
  db_name                         = lower("db-${var.environment}-rds-instance")
  identifier                      = lower("db-${var.environment}-rds-instance")
  multi_az                        = false
  username                        = local.db_username
  password                        = random_password.db_master_pass.result
  apply_immediately               = true
  parameter_group_name            = aws_db_parameter_group.main_db_pg.name
  skip_final_snapshot             = false
  allocated_storage               = 20
  max_allocated_storage           = 512
  vpc_security_group_ids          = [aws_security_group.db_access.id]
  db_subnet_group_name            = aws_db_subnet_group.db_private_subnet_group.name
  deletion_protection             = false
  copy_tags_to_snapshot           = true
  enabled_cloudwatch_logs_exports = ["audit","error","general","slowquery"]
  maintenance_window              = "Mon:00:00-Mon:03:00"
  backup_window                   = "03:00-06:00"
  backup_retention_period         = 7
  storage_encrypted               = false
  tags = local.common_tags
}

resource "aws_security_group" "db_access" {
  name        = "${var.environment}-DB-SG"
  description = "Allow Access to DB for private subnets"
  vpc_id      = aws_vpc.main.id
  ingress = [
    {
      description      = "DB Access"
      protocol         = "tcp"
      from_port        = 3306
      to_port          = 3306
      cidr_blocks      = [for s in aws_subnet.private_subnet : s.cidr_block]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}
