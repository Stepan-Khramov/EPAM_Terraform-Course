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

# resource "aws_internet_gateway" "gateway" {
#      vpc_id = "${aws_vpc.vpc.id}"
#  }


# resource "aws_eip" "nat" {
#   count = 1
#   vpc = true
# }

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "vpc-01"
  cidr = "172.31.1.0/24"

  azs             = ["eu-west-2a", "eu-west-2b"]
  private_subnets = ["172.31.1.0/24", "172.31.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true

  tags = {
    Terraform = "true"
    Environment = "HW_AWS+TF"
  }
}









resource "aws_instance" "server1" {
  ami = "ami-0a2dc38dc30ba417e"
  instance_type = "t2.micro"
}

resource "aws_instance" "server2" {
  ami = "ami-0a2dc38dc30ba417e"
  instance_type = "t2.micro"
}