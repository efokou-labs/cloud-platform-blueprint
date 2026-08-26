terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80"
    }
  }
}

variable "name" {
  type = string
}

variable "recovery_window_days" {
  type    = number
  default = 0
}

resource "aws_secretsmanager_secret" "this" {
  name                    = var.name
  recovery_window_in_days = var.recovery_window_days
}

resource "aws_secretsmanager_secret_version" "placeholder" {
  secret_id = aws_secretsmanager_secret.this.id
  secret_string = jsonencode({
    note = "Replace via CI or External Secrets. Never commit values."
  })
}

output "secret_arn" {
  value = aws_secretsmanager_secret.this.arn
}
