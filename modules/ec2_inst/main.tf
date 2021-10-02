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

resource "aws_instance" "server1" {
  ami = "ami-0a2dc38dc30ba417e"
  instance_type = "t2.micro"
}

resource "aws_instance" "server2" {
  ami = "ami-0a2dc38dc30ba417e"
  instance_type = "t2.micro"
}