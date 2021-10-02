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

# locals {
#   instance-userdata = <<EOF
#     #!/bin/bash
#     export PATH=$PATH:/usr/local/bin
#     which pip >/dev/null
#     if [ $? -ne 0 ];
#     then
#       echo 'PIP NOT PRESENT'
#       if [ -n "$(which yum)" ]; 
#       then
#         yum install -y python-pip
#       else 
#         apt-get -y update && apt-get -y install python-pip
#       fi
#     else 
#       echo 'PIP ALREADY PRESENT'
#     fi
#     EOF
#     }

resource "aws_instance" "aws_wp_inst" {
  ami = "ami-02fb90fdfe894744b"
  instance_type = "t2.micro"

  # user_data_base64 = "${base64encode(local.instance-userdata)}"
  
  tags = {
    Name = "WordPres instance"
    }
}