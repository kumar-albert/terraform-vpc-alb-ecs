locals {
  common_tags = {
    Environment = var.environment
  }

  environment = "${var.environment}"
}

provider "aws" {
  region = "us-west-2"
}
