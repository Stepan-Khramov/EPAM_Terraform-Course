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

resource "aws_vpc" "EPAM_AWS_TF_Course_vpc" {
  cidr_block = var.vpc_ntwk
  instance_tenancy = "default"

  tags = {
    Name = "EPAM_AWS_TF_Course"
  }
}

module "subnet_1" {
  source = "./modules/subnets"
  vpc_id_for_subnet = aws_vpc.EPAM_AWS_TF_Course_vpc.id
  vpc_subnet = "10.10.10.0/24"
  vpc_az = "eu-west-2a"
  
}

module "subnet_2" {
  source = "./modules/subnets"
  vpc_id_for_subnet = aws_vpc.EPAM_AWS_TF_Course_vpc.id
  vpc_subnet = "10.10.20.0/24"
  vpc_az = "eu-west-2b"
  
}