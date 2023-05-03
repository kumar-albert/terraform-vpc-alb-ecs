locals {
  common_tags = {
    Environment = var.environment
  }

  environment = var.environment
  db_username = "admin"
}

