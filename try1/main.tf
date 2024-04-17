terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}



provider "aws" {
    region="eu-west-3"
    access_key = "AKIAW3MD7XBC7GMF3TVJ"
    secret_key = "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"
}


resource "tls_private_key" "rsa_4096" {
  algorithm = "RSA"
  rsa_bits  = 4096
}


variable "key_name" {

}
resource "aws_key_pair" "key_pair" {
  key_name   = var.key_name
  public_key = tls_private_key.rsa_4096.public_key_openssh
}

resource "local_file" "private_key" {
content =tls_private_key.rsa_4096.private_key_pem
filename = var.key_name

}

resource "aws_instance" "hackathon_instance" {
  ami           = "ami-00c71bd4d220aa22a"
  instance_type = "t2.micro"
  key_name= aws_key_pair.key_pair.key_name

  tags = {
    Name = "terrraform_instance"
  }
}