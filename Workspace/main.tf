provider "aws" {
  region = "us-east-1"
}

variable "ami" {
  description = ""
}

variable "instance_type" {
  description = "value"
  type = map(string)

  default = {
    "dev" = "t2.micro"
    "stage" = "t2.medium"
    "prod" = "t2.large"
  }
}

module "example" {
  source = "./modules/ec2-instance"
  ami = var.ami
  instance_type = lookup(var.instance_type,terraform.workspace,"t2.micro")
}


