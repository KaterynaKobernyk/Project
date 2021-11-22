resource "aws_vpc" "project_vpc" {
    cidr_block = "${var.vpc_cidr}"
    enable_dns_hostnames = true
    tags = {
      Name = "Project VPC"
    }
}

resource "aws_internet_gateway" "project_int_gateway" {
    vpc_id = "${aws_vpc.project_vpc.id}"
    tags = {
      Name = "project_int_gateway"
    }
}

/*
  NAT Instance
*/
resource "aws_security_group" "nat" {
    name = "security_group_vpc_nat"
    description = "Allow traffic to pass from the private subnet to the internet"

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["${var.private_subnet_cidr}"]
    }
    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["${var.private_subnet_cidr}"]
    }
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
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
    egress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["${var.vpc_cidr}"]
    }
    egress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    vpc_id = "${aws_vpc.project_vpc.id}"

    tags = {
        Name = "NATSG"
    }
}

resource "aws_instance" "nat" {
    ami = "ami-0046c079820366dc3" # this is a special ami preconfigured to do NAT
    availability_zone = "us-west-1a"
    instance_type = "t2.micro"
    key_name = "${var.aws_key_name}"
    vpc_security_group_ids = ["${aws_security_group.nat.id}"]
    subnet_id = "${aws_subnet.us-west-1a-public.id}"
    associate_public_ip_address = true
    source_dest_check = false

    tags = {
        Name = "VPC NAT"
    }
}

resource "aws_eip" "nat" {
    instance = "${aws_instance.nat.id}"
    vpc = true
}

/*
  Public Subnet
*/
resource "aws_subnet" "us-west-1a-public" {
    vpc_id = "${aws_vpc.project_vpc.id}"

    cidr_block = "${var.public_subnet_cidr}"
    availability_zone = "us-west-1a"

    tags = {
        Name = "Public Subnet"
    }
}

resource "aws_route_table" "us-west-1a-public" {
    vpc_id = "${aws_vpc.project_vpc.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.project_int_gateway.id}"
    }

    tags = {
        Name = "Public Subnet"
    }
}

resource "aws_route_table_association" "us-west-1a-public" {
    subnet_id = "${aws_subnet.us-west-1a-public.id}"
    route_table_id = "${aws_route_table.us-west-1a-public.id}"
}

/*
  Private Subnet
*/
resource "aws_subnet" "us-west-1a-private" {
    vpc_id = "${aws_vpc.project_vpc.id}"

    cidr_block = "${var.private_subnet_cidr}"
    availability_zone = "us-west-1a"

    tags = {
        Name = "Private Subnet"
    }
}


resource "aws_route_table" "us-west-1a-private" {
    vpc_id = "${aws_vpc.project_vpc.id}"

    route {
        cidr_block = "0.0.0.0/0"
        instance_id = "${aws_instance.nat.id}"
    }

    tags = {
        Name = "Private Subnet"
    }
}

resource "aws_route_table_association" "us-west-1a-private" {
    subnet_id = "${aws_subnet.us-west-1a-private.id}"
    route_table_id = "${aws_route_table.us-west-1a-private.id}"
}



resource "aws_subnet" "us-west-1c-private" {
    vpc_id = "${aws_vpc.project_vpc.id}"

    cidr_block = "${var.private_subnet_cidr2}"
    availability_zone = "us-west-1c"

    tags = {
        Name = "Private Subnet"
    }
}

resource "aws_route_table" "us-west-1c-private" {
    vpc_id = "${aws_vpc.project_vpc.id}"

    route {
        cidr_block = "0.0.0.0/0"
        instance_id = "${aws_instance.nat.id}"
    }

    tags = {
        Name = "Private Subnet2"
    }
}

resource "aws_route_table_association" "us-west-1c-private" {
    subnet_id = "${aws_subnet.us-west-1c-private.id}"
    route_table_id = "${aws_route_table.us-west-1c-private.id}"
}
