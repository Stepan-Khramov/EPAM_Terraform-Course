terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = "eu-west-2"
  
  }


resource "aws_subnet" "vpc_subnet" {
  vpc_id = var.vpc_id_for_subnet
  cidr_block = var.vpc_subnet_cidr
  availability_zone = var.subnet_az


  }