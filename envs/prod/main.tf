terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80"
    }
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "name" {
  type    = string
  default = "portfolio-prod"
}

variable "create_expensive_data_plane" {
  type        = bool
  default     = false
  description = "When false, only budget + registry are created. Set true only for a short-lived demo, then destroy."
}

variable "db_password" {
  type      = string
  sensitive = true
  default   = "change-me-in-ci-not-in-git"
}

module "budget" {
  source    = "../../modules/observability"
  name      = var.name
  limit_usd = "10"
}

module "registry" {
  source = "../../modules/registry"
  name   = var.name
}

module "network" {
  count  = var.create_expensive_data_plane ? 1 : 0
  source = "../../modules/network"
  name   = var.name
}

module "kubernetes" {
  count      = var.create_expensive_data_plane ? 1 : 0
  source     = "../../modules/kubernetes"
  name       = var.name
  vpc_id     = module.network[0].vpc_id
  subnet_ids = concat(module.network[0].public_subnet_ids, module.network[0].private_subnet_ids)
}

module "database" {
  count      = var.create_expensive_data_plane ? 1 : 0
  source     = "../../modules/database"
  name       = var.name
  vpc_id     = module.network[0].vpc_id
  subnet_ids = module.network[0].private_subnet_ids
  password   = var.db_password
}

module "secrets" {
  count  = var.create_expensive_data_plane ? 1 : 0
  source = "../../modules/secrets"
  name   = "${var.name}/app"
}

output "budget_name" {
  value = module.budget.budget_name
}

output "repository_url" {
  value = module.registry.repository_url
}
