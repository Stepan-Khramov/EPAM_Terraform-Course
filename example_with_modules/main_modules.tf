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
  vpc_subnet_cidr = "10.10.10.0/24"
  subnet_az = "eu-west-2a"
  
}

module "subnet_2" {
  source = "./modules/subnets"
  vpc_id_for_subnet = aws_vpc.EPAM_AWS_TF_Course_vpc.id
  vpc_subnet_cidr = "10.10.20.0/24"
  subnet_az = "eu-west-2b"
  
}

module "netwk_int_inst_1" {
  source = "./modules/ntwk_int"
  ntwk_int_subnet_id = module.subnet_1.id
  inst_private_ip = "10.10.10.1"
  attchmnt_inst = aws_instance.aws_wp_inst.inst_1
}

module "netwk_int_inst_2" {
  source = "./modules/ntwk_int"
  ntwk_int_subnet_id = module.subnet_2.id
  inst_private_ip = "10.10.20.1"
  attchmnt_inst = aws_instance.aws_wp_inst.inst_2
}

module "inst_1" {
  source = "./modules/ec2_inst"

  
}

module "inst_2" {
  source = "./modules/ec2_inst"

  
}