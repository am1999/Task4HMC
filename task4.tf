provider "aws" {
  region = "ap-south-1"
  profile= "terrapro"
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "task4vpc" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames= true
  enable_dns_support   = true

  tags = {
    Name = "task4vpc"
  }
}

resource "aws_security_group" "publicsg_task4" {
  name        = "wordpress"
  description = "Allow TLS inbound traffic"
  vpc_id      = "${aws_vpc.task4vpc.id}"


ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = [aws_vpc.task4vpc.cidr_block]
  }

 ingress {
    
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 ingress {
    
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "publicsg_task4"
  }
}

resource "aws_security_group" "privatesg_task4" {
  name        = "mysql_sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = "${aws_vpc.task4vpc.id}"
  
 
ingress {
    
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["192.168.2.0/24"]
  }
ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = [aws_vpc.task4vpc.cidr_block]
  }

ingress {
  from_port   = 3306
  to_port     = 3306
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
egress { 
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
 }
 tags = {
    Name = "privatesg_task4"
  }

}

resource "aws_subnet" "public_subnet_task4" {
  vpc_id     = "${aws_vpc.task4vpc.id}"
  cidr_block = "192.168.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet_task4"
  }
}

resource "aws_subnet" "private_subnet_task4" {
  vpc_id     = "${aws_vpc.task4vpc.id}"
  cidr_block = "192.168.3.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = {
    Name = "private_subnet_task4"
  }
}



resource "aws_internet_gateway" "igw_task4" {
  vpc_id = "${aws_vpc.task4vpc.id}"

  tags = {
    Name = "igw_task4"
  }
}

resource "aws_eip" "test-eip" {
  vpc = true
}

resource "aws_nat_gateway" "nat-gateway" {
  allocation_id = "${aws_eip.test-eip.id}"
  subnet_id     = "${aws_subnet.public_subnet_task4.id}"
}


resource "aws_route_table" "public_route_task4" {
  vpc_id = "${aws_vpc.task4vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw_task4.id}"
}

tags = {
    Name = "public_route_task4"
  }
}
  

resource "aws_default_route_table" "private_route_task4" {
  default_route_table_id = "${aws_vpc.task4vpc.default_route_table_id}"

  route {
    nat_gateway_id = "${aws_nat_gateway.nat-gateway.id}"
    cidr_block     = "0.0.0.0/0"
  }

  tags = {
    Name = "private-route-table"
  }
}

resource "aws_route_table_association" "public_subnet_assoc" {
  route_table_id = "${aws_route_table.public_route_task4.id}"
  subnet_id      = "${aws_subnet.public_subnet_task4.id}"
  depends_on     = ["aws_route_table.public_route_task4", "aws_subnet.public_subnet_task4"]
}

resource "aws_route_table_association" "private_subnet_assoc" {
   route_table_id = "${aws_default_route_table.private_route_task4.id}"
  subnet_id      = "${aws_subnet.private_subnet_task4.id}"
  depends_on     = ["aws_default_route_table.private_route_task4", "aws_subnet.private_subnet_task4"]
}


resource "aws_instance" "mysql_task4" {
  ami           = "ami-0af4f2ae8f9fac390"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.privatesg_task4.id}"] 
  subnet_id     = "${aws_subnet.private_subnet_task4.id}"
  key_name     =  "key1"
 
 tags = {
  Name = "mysql_task4"
  }
}

resource "aws_instance" "wordpress_task4" {
  ami           = "ami-ff82f990"
  instance_type = "t2.micro"
  key_name     =  "key1" 
  vpc_security_group_ids = ["${aws_security_group.publicsg_task4.id}"] 
  subnet_id     = "${aws_subnet.public_subnet_task4.id}"
  
  tags = {
  Name = "wordpress_task4"
  }
  
}