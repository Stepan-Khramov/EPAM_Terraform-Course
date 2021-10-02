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

resource "aws_network_interface" "inst_ntwk_int" {
  subnet_id = var.ntwk_int_subnet_id
  private_ip = var.inst_private_ip

  attachment {
    instance = var.attchmnt_inst
  }


  tags = {
    Name = "primary_instance_network_interface"
  }
}
