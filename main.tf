resource "aws_instance" "Natinstance" {
  ami               = var.ami_nat
  instance_type     = var.instance_types
  subnet_id         = aws_subnet.subnet_public.id
  security_groups   = [aws_security_group.sg_nat.id]
  source_dest_check = false
  tags = {
    Name = "${var.name} - NAT"
  }
}

resource "aws_launch_configuration" "launch_configuration" {
  name            = "${var.name} - Launch_config"
  image_id        = var.ami
  instance_type   = var.instance_types
  security_groups = [aws_security_group.sg_instance.id]
  user_data       = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2
              yum install -y httpd mariadb-server
              systemctl start httpd
              systemctl enable httpd
              usermod -a -G apache ec2-user
              chown -R ec2-user:apache /var/www
              chmod 2775 /var/www && find /var/www -type d -exec sudo chmod 2775 {} \;
              cd /var/www/html
              wget https://github.com/mplesha/NoviNano/releases/download/v1.0/20180706_novinano_nk_71b6e5d0e46a01132850180706065954_archive.zip https://github.com/mplesha/NoviNano/releases/download/v1.0/20180706_novinano_nk_71b6e5d0e46a01132850180706065954_installer.php
              cp 20180706_novinano_nk_71b6e5d0e46a01132850180706065954_installer.php installer.php
              rm -r 20180706_novinano_nk_71b6e5d0e46a01132850180706065954_installer.php
              EOF
}
resource "aws_autoscaling_group" "autoscalling_group" {
  name                      = "${var.name} - Autoscaling-group"
  max_size                  = 3
  min_size                  = 1
  health_check_grace_period = 50
  health_check_type         = "EC2"
  desired_capacity          = 2
  force_delete              = true
  vpc_zone_identifier       = [aws_subnet.subnet_public.id]
  launch_configuration      = aws_launch_configuration.launch_configuration.name
  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_autoscaling_policy" "autoscalling_policy" {
  name                   = "${var.name} - Autoscaling-policy"
  autoscaling_group_name = aws_autoscaling_group.autoscalling_group.name
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 40.0
  }
}
resource "aws_db_subnet_group" "sg_db" {
  name       = "${var.name} - sg_db"
  subnet_ids = [aws_subnet.subnet_private01.id, aws_subnet.subnet_private02.id]
}
resource "aws_db_instance" "db" {
  allocated_storage      = 20
  engine                 = "mysql"
  engine_version         = "8.0.23"
  instance_class         = "db.t2.micro"
  name                   = var.db_namedb
  username               = var.db_adminnamedb
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.sg_db.name
  vpc_security_group_ids = ["${aws_security_group.rds.id}"]
  parameter_group_name   = "default.mysql8.0"
  skip_final_snapshot    = true
}
resource "aws_vpc" "vpc" {
  cidr_block           = "10.10.20.0/24"
  enable_dns_support   = true
  enable_dns_hostnames = true


}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.name} - igw"
  }
}

resource "aws_subnet" "subnet_public" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.10.20.0/27"
  map_public_ip_on_launch = "true"
  availability_zone       = "eu-west-3a"
  tags = {
    Name = "${var.name} - Subnet_public"
  }
}
resource "aws_subnet" "subnet_private01" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.10.20.32/27"
  map_public_ip_on_launch = "false"
  availability_zone       = "eu-west-3b"
  tags = {
    Name = "${var.name} - subnet_private01"
  }

}
resource "aws_subnet" "subnet_private02" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.10.20.64/27"
  map_public_ip_on_launch = "false"
  availability_zone       = "eu-west-3c"

  tags = {
    Name = "${var.name} - subnet_private02"
  }

}

resource "aws_route_table" "rtb_public" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "${var.name} - public"
  }
}
resource "aws_route_table" "rtb_privat" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block  = "0.0.0.0/0"
    instance_id = aws_instance.Natinstance.id
  }
  tags = {
    Name = "${var.name} - privat"
  }
}
resource "aws_route_table_association" "rta_subnet_public" {
  subnet_id      = aws_subnet.subnet_public.id
  route_table_id = aws_route_table.rtb_public.id

}

resource "aws_route_table_association" "rta_subnet_private01" {
  subnet_id      = aws_subnet.subnet_private01.id
  route_table_id = aws_route_table.rtb_privat.id

}
resource "aws_route_table_association" "rta_subnet_private02" {
  subnet_id      = aws_subnet.subnet_private02.id
  route_table_id = aws_route_table.rtb_privat.id

}
resource "aws_security_group" "sg_nat" {
  name   = "${var.name}-sg_nat"
  vpc_id = aws_vpc.vpc.id
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.name} - sg_nat"
  }
}
resource "aws_security_group" "sg_instance" {
  name   = "${var.name}-sg_instance"
  vpc_id = aws_vpc.vpc.id
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
    Name = "${var.name} - sg_instance"
  }
}
resource "aws_security_group" "rds" {
  name   = "${var.name}-rds_security_group"
  vpc_id = aws_vpc.vpc.id
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = ["${aws_security_group.sg_instance.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
