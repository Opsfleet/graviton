terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  profile = "opsfleet"
  default_tags {
    tags = {
      Project = "graviton"
    }
  }
}