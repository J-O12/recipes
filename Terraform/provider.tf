# terraform {
#   backend "s3" {
#     bucket = "statebucket4joel"
#     dynamodb_table = "State-lock"
#     key = "global/mystatefile/terraform.tfstate"
#     region = "ap-southeast-2"
#     encrypt = true
#   }
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = "~> 5.0"
#     }
#   }
# }

# provider "aws" {
#   region = "ap-southeast-2"
#   # Configuration options
# }