data "aws_region" "current" {}
data "aws_availability_zones" "available" {}


variable "environment" {
  description = "Environment Name for prefix"
  type        = string
  default     = "developmemt"
}

variable "vpc_cidr" {
  description = "CIDR range for the VPC"
  type        = string
  default     = "10.88.0.0/16"
}


