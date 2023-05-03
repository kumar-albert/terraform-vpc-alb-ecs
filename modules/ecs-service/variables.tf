variable "environment" {
  description = "environment name"
  type        = string
}

variable "service_name" {
  description = "service name"
  type        = string
}

variable "image_uri" {
  description = "ecr image uri"
  type        = string
}

variable "tags" {
  description = "resource tags"
  type        = map
}

variable "vpc_id" {
  description = "vpc id"
  type        = string
}

variable "lb_security_group" {
  description = "load balancer security group id"
  type        = string
}

variable "health_check_url" {
  description = "healthcheck url"
  type        = string
}


variable "ecs_cluster_id" {
  description = "ecs cluster id"
  type        = string
}

variable "subnet_ids" {
  description = "subnet ids"
  type        = list
}

variable "container_env" {
  description = "service environment variables"
  type        = any
}

