terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.21.0"
    }
  }
}

provider "aws" {
  region                   = "eu-central-1"
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "default"
}