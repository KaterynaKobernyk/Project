/*
  Database Servers
*/
resource "aws_security_group" "db" {
    name = "security_group_vpc_db"
    description = "Allow incoming database connections."

    ingress { # SQL Server
        from_port = 1433
        to_port = 1433
        protocol = "tcp"
        security_groups = ["${aws_security_group.web.id}"]
    }
    ingress { # MySQL
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        security_groups = ["${aws_security_group.web.id}"]
    }

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["${var.vpc_cidr}"]
    }
    ingress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = ["${var.vpc_cidr}"]
    }

    egress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    vpc_id = "${aws_vpc.project_vpc.id}"

    tags = {
        Name = "DBServerSG"
    }
}


resource "aws_instance" "db-1" {
    ami = "${lookup(var.amis, var.aws_region)}"
    availability_zone = "us-west-1a"
    instance_type = "t2.micro"
    key_name = "${var.aws_key_name}"
    vpc_security_group_ids = ["${aws_security_group.db.id}"]
    subnet_id = "${aws_subnet.us-west-1a-private.id}"
    source_dest_check = false

    tags = {
        Name = "DB Server 1"
    }
}

/*
RDS
*/

resource "aws_db_subnet_group" "db-subnet" {
  name       = "db subnet group"
  subnet_ids = [aws_subnet.us-west-1a-private.id, aws_subnet.us-west-1c-private.id]

  tags = {
    Name = "My DB subnet group"
  }
}

resource "aws_db_instance" "rds" {
  identifier                = "${var.rds_instance_identifier}"
  allocated_storage         = 5
  engine                    = "mysql"
  engine_version            = "8.0"
  instance_class            = "db.t2.micro"
  name                      = "${var.database_name}"
  username                  = "${var.database_user}"
  password                  = "${var.database_password}"
  db_subnet_group_name      = "${aws_db_subnet_group.db-subnet.id}"
  vpc_security_group_ids    = ["${aws_security_group.db.id}"]
  skip_final_snapshot       = true
}

resource "aws_db_parameter_group" "mysql" {
  name        = "${var.rds_instance_identifier}-param-group"
  family      = "mysql8.0"
  parameter {
    name  = "character_set_server"
    value = "utf8"
  }
  parameter {
    name  = "character_set_client"
    value = "utf8"
  }
}