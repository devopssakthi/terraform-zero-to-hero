provider "aws" {
    region = "us-east-1"

}

variable "ami" {
  description = "value"
}

variable "instance_type" {
  description = "value"
}

resource "aws_instance" "ec2-machine" {
  ami = var.ami
  instance_type = var.instance_type
}