locals {
  environment           = "development"
  vpc_cidr              = "10.88.0.0/16"
  #Backend Config
  backend_region = "us-west-2"                         
  backend_s3_key = "${basename(get_terragrunt_dir())}"
}

terraform {
  source = "./terraform"
}

inputs = {
  environment           = local.environment
  vpc_cidr              = local.vpc_cidr
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.backend_region}"
}
EOF
}

# remote_state {
#   backend = "s3"
#   config = {
#     bucket  = lower("${local.environment}-terraform")
#     key     = "rds/${local.backend_s3_key}/tfstate.tfstate"
#     region  = "${local.backend_region}"
#     encrypt = true
#   }
#   generate = {
#     path      = "backend.tf"
#     if_exists = "overwrite_terragrunt"
#   }
# }
