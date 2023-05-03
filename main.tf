locals {
  common_tags = {
    Environment = var.environment
  }

  environment = "${var.environment}"
  db_username = "admin"
}

provider "aws" {
  region = "us-west-2"
}
