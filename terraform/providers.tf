
terraform {
  required_version = ">= 1.8.0"

  backend "s3" {
    bucket         = "my-terraform-backend-deball"
    key            = "deball/repo/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks-12345"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      ManagedBy = "Terraform"
    }
}
}
