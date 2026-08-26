# Local/file backend is acceptable for kind-centric work.
# For AWS, switch to S3 + DynamoDB locking before the first shared apply.
#
# terraform {
#   backend "s3" {
#     bucket         = "efokou-labs-tfstate"
#     key            = "cloud-platform/prod/terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "efokou-labs-tf-locks"
#     encrypt        = true
#   }
# }
