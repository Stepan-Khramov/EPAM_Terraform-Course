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
  cidr_block = "10.10.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "EPAM_AWS_TF_Course"
  }
}

resource "aws_subnet" "vpc_subnet_1" {
  vpc_id = aws_vpc.EPAM_AWS_TF_Course_vpc.id
  cidr_block = "10.10.10.0/24"
  availability_zone = "eu-west-2a"
  }

resource "aws_subnet" "vpc_subnet_2" {
  vpc_id = aws_vpc.EPAM_AWS_TF_Course_vpc.id
  cidr_block = "10.10.20.0/24"
  availability_zone = "eu-west-2b"
}

resource "aws_network_interface" "inst_1_ntwk_int" {
  subnet_id = aws_subnet.vpc_subnet_1.id
  private_ip = "10.10.10.1"

  attachment {
    instance = "aws_wp_inst_1"
    device_index = 0
  }
  tags = {
    Name = "primary_instance_network_interface"
  }
}

resource "aws_network_interface" "inst_2_ntwk_int" {
  subnet_id = aws_subnet.vpc_subnet_2.id
  private_ip = "10.10.20.1"

  attachment {
    instance = "aws_wp_inst_2"
    device_index = 0
  }
  tags = {
    Name = "primary_instance_network_interface"
  }
}

resource "aws_efs_file_system" "efs_for_mp_db" {
  
  tags = {
      Name = "EFS for WordPress database"
  }
}

resource "aws_efs_mount_target" "EFS_mount_target_inst1" {
  file_system_id = aws_efs_file_system.efs_for_mp_db.id
  subnet_id = aws_subnet.vpc_subnet_1.id
}

resource "aws_efs_mount_target" "EFS_mount_target_inst2" {
  file_system_id = aws_efs_file_system.efs_for_mp_db.id
  subnet_id = aws_subnet.vpc_subnet_2.id
}

resource "aws_instance" "aws_wp_inst_1" {
  ami = "ami-02fb90fdfe894744b"
  instance_type = "t2.micro"

  tags = {
    Name = "WordPres instance"
    }
}

resource "aws_instance" "aws_wp_inst_2" {
  ami = "ami-02fb90fdfe894744b"
  instance_type = "t2.micro"

  tags = {
    Name = "WordPres instance"
    }
}


