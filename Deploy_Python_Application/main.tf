provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    "name" = "myvpc"
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "devops-key"
  public_key = file("~/.ssh/id_rsa.pub")
}


resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone = "us-east-1a"
  tags = {
    Name = "Main-subnet"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "main-gw"
  }
}

resource "aws_route_table" "RT" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.RT.id
}

resource "aws_security_group" "webSg" {
  name        = "web"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "web-sg"
  }
}

resource "aws_instance" "server" {
  ami                    = "ami-0261755bbcb8c4a84"
  instance_type          = "t2.micro"
  key_name = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.webSg.id]
  subnet_id = aws_subnet.main.id
   tags = {
    Name = "python-app"
  }
  connection {
    type = "ssh"
    user = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
    host = self.public_ip
  }

  provisioner "file" {
     source = "app.py"
     destination = "/home/ubuntu/app.py"
  }

  provisioner "remote-exec" {
    inline = [ 
        "echo 'Hello from instance'",
        "sudo apt update -y",  # Update package lists (for ubuntu)
        "sudo apt-get install -y python3-pip",  # Example package installation
        "cd /home/ubuntu",
        "sudo pip3 install flask",
        "sudo python3 app.py"
     ]
  }

}   