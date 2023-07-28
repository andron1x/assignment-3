##################### VPC ######################################

resource "aws_vpc" "wordpress-vpc" {
   cidr_block = "10.0.0.0/16"
   tags = {
    Name = "wordpress-vpc"
   } 
}

# Gateway
resource "aws_internet_gateway" "wordpress_igw" {
    vpc_id = aws_vpc.wordpress-vpc.id
    tags = {
      Name = "wordpress_igw"
    }
}

#Public Subnets
resource "aws_subnet" "public_subnets" {
  count = 3
  cidr_block = "10.0.1${count.index}.0/24"
  vpc_id = aws_vpc.wordpress-vpc.id
  availability_zone = "us-east-1${element(["a", "b", "c"], count.index)}"
  tags = {
    Name = "public-subnet-${count.index}"
  }

}

#Private subnets
resource "aws_subnet" "private_subnets" {
  count = 3
  cidr_block = "10.0.2${count.index}.0/24"
  vpc_id = aws_vpc.wordpress-vpc.id
  availability_zone = "us-east-1${element(["a", "b", "c"], count.index)}"
  tags = {
    Name = "private-subnet-${count.index}"
  }
}

#Route tables 
resource "aws_route_table" "wordpess-rt" {
    vpc_id = aws_vpc.wordpress-vpc.id
    route  {
  cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.wordpress_igw.id
  }
  tags = {
    Name = "wordpess-rt"
    }
}

#Route table assosiation 
 resource "aws_route_table_association" "public_subnet_association" {
  count = 3
  subnet_id = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.wordpess-rt.id
}


##################### SECURITY GROUP #########################

resource "aws_security_group" "wordpress-sg" {
    name = "wordpress-sg"
    description = "SSH, HTTP, HTTPS"
    vpc_id = aws_vpc.wordpress-vpc.id

ingress {
    description = "SSH 20"
    from_port = var.ingress_ports[0]
    to_port = var.ingress_ports[0]
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}
ingress {
    description = "HTTP 80"
    from_port = var.ingress_ports[1]
    to_port = var.ingress_ports[1]
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}
ingress {
    description = "HTTPS 443"
    from_port = var.ingress_ports[2]
    to_port = var.ingress_ports[2]
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}
egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

####################### KEY PAIR ##################

resource "aws_key_pair" "ssh-key" {
    key_name = "ssh-key"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCoeK/qVSe05TQcUPx702NpvRpnOQo2mIbPGJR+dF4O24dRFiN6mlu7Uidg/olIc9oh+4Lv3B9cXCY7MnZEeBlLRNhyOxRE7zjIvACs/suRE5RuN/ZpbrgVwQY3rfbpztJ5lc7vWqK4PfV8frW6egZ8mdcUh+UChYxzCSEUZYgTbb3YFXDaQlzNFDsumAye2pVtJbQPq/c1vyLSN6501bh6/swyccXlVqVpLfgmRNNd22cIXFijLOc2ws7nxA8ThwfmhB/zAIXIDmb9bgzmMREFlsPspfc4hxex+ZB3Qp0Uv/8ALK90VwOSyI/41tO+wal9e88jOEOOTNqyeHZwDuJpbKeu0HwY+pAWRxUZFIHjwf3YkQqtfc91h99Bdv1OD29IMl13e67OmFg/635M/nGyqhbPa4l+brPkk22E2W78RYE/z4ekpqeMtVYGmFfVzQqwFFPgxj7i5FtW+HtZIQd3AA5hnF1dhaSd3u3ejMYwyoFL1XvHQEehFEsLMY/3nEE= andron1x@andron1x-TP"

}

####################### EC2 WORDPRESS ###############

resource "aws_instance" "wordpress-ec2" {
    ami = var.ami
    instance_type = "t2.micro"
    subnet_id = aws_subnet.public_subnets[0].id
    associate_public_ip_address = true 
    key_name = aws_key_pair.ssh-key.id
    tags = {
        Name = "wordpress-ec2"
    }
    vpc_security_group_ids = [aws_security_group.wordpress-sg.id]
}


######################## RDS Security Group #################################
resource "aws_security_group" "rds-sg" {
   name = "rds-sg"
   description = "RDS security group"
   vpc_id = aws_vpc.wordpress-vpc.id
   ingress {
     from_port       = 3306
     to_port         = 3306
     protocol        = "tcp"  
     security_groups = [aws_security_group.wordpress-sg.id]
   }
   tags = {
     name = "rds-sg"
   }
 }

 ################## DB ###############################

 resource "aws_db_subnet_group" "rds_subnet_group" {
   name       = "rds_subnet_group"
   subnet_ids = [aws_subnet.private_subnets[1].id, aws_subnet.private_subnets[2].id]
 }
resource "aws_db_instance" "mysql" {
   allocated_storage    = 20
   engine               = "mysql"
   engine_version       = "5.7"
   instance_class       = "db.t2.micro"
   identifier           = "mysql"
   username             = "admin"
   password             = "adminadmin"
   db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
   vpc_security_group_ids = [aws_security_group.rds-sg.id]
 }




