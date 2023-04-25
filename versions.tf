terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.35"
    }
    mysql = {
      source  = "petoju/mysql"
      version = "3.0.36"
    }
  }

  required_version = ">= 0.15"
}
