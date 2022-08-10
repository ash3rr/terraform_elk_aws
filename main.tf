resource "aws_budgets_budget" "test_elk_setup_budget" {
  name         = "monthly-budget"
  budget_type  = "COST"
  limit_amount = "100.0"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
}

resource "aws_vpc" "elk_vpc" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "dev-elk"
  }
}

resource "aws_subnet" "elk_public_subnet" {
  vpc_id                  = aws_vpc.elk_vpc.id
  cidr_block              = "10.123.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "dev-elk-public"
  }
}

resource "aws_internet_gateway" "elk_internet_gateway" {
  vpc_id = aws_vpc.elk_vpc.id
  tags   = { Name = "dev-elk-igw" }
}

resource "aws_route_table" "elk_public_rt" {
  vpc_id = aws_vpc.elk_vpc.id
  tags   = { Name = "dev-elk-rt" }
}

resource "aws_route" "dev-elk-default-route" {
  route_table_id         = aws_route_table.elk_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.elk_internet_gateway.id
}

resource "aws_route_table_association" "elk_public_assoc" {
  subnet_id      = aws_subnet.elk_public_subnet.id
  route_table_id = aws_route_table.elk_public_rt.id
}

resource "aws_security_group" "elk_sg" {
  name        = "elk_sg"
  description = "elk security group"
  vpc_id      = aws_vpc.elk_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["37.47.141.250/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_key_pair" "elk_auth" {
  key_name   = "elk_key"
  public_key = file("~/.ssh/elk_key.pub")
}
// VM Configuration: 1 Master (running all ELK services), 10 Slaves (Data/Master/Ingest nodes)
// Master: T3a.xlarge w/30GB + 200GB Slaves: r5a.xlarge w/80GB + 1500GB

resource "aws_instance" "elk_master" {
  instance_type          = "t3a.large"
  ami                    = data.aws_ami.server_ami.id
  key_name               = aws_key_pair.elk_auth.id
  vpc_security_group_ids = [aws_security_group.elk_sg.id]
  subnet_id              = aws_subnet.elk_public_subnet.id
  #user_data              = file("userdata.tpl")
  root_block_device {
    volume_size = 30
  }

  tags = {
    Name = "elk-master"
  }

}

resource "aws_ebs_volume" "datavol_master1" {
  availability_zone = aws_instance.elk_master.availability_zone
  size              = 200
  tags = {
    Name = "data-volume"
  }
}
resource "aws_volume_attachment" "elk_data_vol_attach" {
  device_name = "/dev/sdd"
  volume_id   = aws_ebs_volume.datavol_master1.id
  instance_id = aws_instance.elk_master.id
}


//  Elastic node 1
resource "aws_instance" "elk_node1" {
  instance_type          = "r5a.xlarge"
  ami                    = data.aws_ami.server_ami.id
  key_name               = aws_key_pair.elk_auth.id
  vpc_security_group_ids = [aws_security_group.elk_sg.id]
  subnet_id              = aws_subnet.elk_public_subnet.id
  #user_data              = file("userdata.tpl")
  root_block_device {
    volume_size = 80
  }

  tags = {
    Name = "elk-node"

  }

}

resource "aws_ebs_volume" "datavol_node1" {
  availability_zone = aws_instance.elk_node1.availability_zone
  size              = 1500
  tags = {
    Name = "data-volume"
  }
}
resource "aws_volume_attachment" "elk_data_vol_attach_node1" {
  device_name = "/dev/sdd"
  volume_id   = aws_ebs_volume.datavol_node1.id
  instance_id = aws_instance.elk_node1.id
}

/*
//  Elastic node 2
resource "aws_instance" "elk_node2" {
  instance_type          = "r5a.xlarge"
  ami                    = data.aws_ami.server_ami.id
  key_name               = aws_key_pair.elk_auth.id
  vpc_security_group_ids = [aws_security_group.elk_sg.id]
  subnet_id              = aws_subnet.elk_public_subnet.id
  #user_data              = file("userdata.tpl")
  root_block_device {
    volume_size = 80
  }

  tags = {
    Name = "elk-node"

  }

}

resource "aws_ebs_volume" "datavol_node2" {
  availability_zone = aws_instance.elk_node1.availability_zone
  size              = 1500
  tags = {
    Name = "data-volume"
  }
}
resource "aws_volume_attachment" "elk_data_vol_attach_node2" {
  device_name = "/dev/sdd"
  volume_id   = aws_ebs_volume.datavol_node2.id
  instance_id = aws_instance.elk_node2.id
}


//  Elastic node 3
resource "aws_instance" "elk_node3" {
  instance_type          = "r5a.xlarge"
  ami                    = data.aws_ami.server_ami.id
  key_name               = aws_key_pair.elk_auth.id
  vpc_security_group_ids = [aws_security_group.elk_sg.id]
  subnet_id              = aws_subnet.elk_public_subnet.id
  //user_data              = file("userdata.tpl")
  root_block_device {
    volume_size = 80
  }

  tags = {
    Name = "elk-node"

  }

}

resource "aws_ebs_volume" "datavol_node3" {
  availability_zone = aws_instance.elk_node1.availability_zone
  size              = 1500
  tags = {
    Name = "data-volume"
  }
}
resource "aws_volume_attachment" "elk_data_vol_attach_node3" {
  device_name = "/dev/sdd"
  volume_id   = aws_ebs_volume.datavol_node3.id
  instance_id = aws_instance.elk_node3.id
}


//  Elastic node 4
resource "aws_instance" "elk_node4" {
  instance_type          = "r5a.xlarge"
  ami                    = data.aws_ami.server_ami.id
  key_name               = aws_key_pair.elk_auth.id
  vpc_security_group_ids = [aws_security_group.elk_sg.id]
  subnet_id              = aws_subnet.elk_public_subnet.id
  //user_data              = file("userdata.tpl")
  root_block_device {
    volume_size = 80
  }

  tags = {
    Name = "elk-node"

  }

}

resource "aws_ebs_volume" "datavol_node4" {
  availability_zone = aws_instance.elk_node4.availability_zone
  size              = 1500
  tags = {
    Name = "data-volume"
  }
}
resource "aws_volume_attachment" "elk_data_vol_attach_node4" {
  device_name = "/dev/sdd"
  volume_id   = aws_ebs_volume.datavol_node4.id
  instance_id = aws_instance.elk_node4.id
}


//  Elastic node 5
resource "aws_instance" "elk_node5" {
  instance_type          = "r5a.xlarge"
  ami                    = data.aws_ami.server_ami.id
  key_name               = aws_key_pair.elk_auth.id
  vpc_security_group_ids = [aws_security_group.elk_sg.id]
  subnet_id              = aws_subnet.elk_public_subnet.id
  //user_data              = file("userdata.tpl")
  root_block_device {
    volume_size = 80
  }

  tags = {
    Name = "elk-node"

  }

}

resource "aws_ebs_volume" "datavol_node5" {
  availability_zone = aws_instance.elk_node5.availability_zone
  size              = 1500
  tags = {
    Name = "data-volume"
  }
}
resource "aws_volume_attachment" "elk_data_vol_attach_node5" {
  device_name = "/dev/sdd"
  volume_id   = aws_ebs_volume.datavol_node5.id
  instance_id = aws_instance.elk_node5.id
}


//  Elastic node 6
resource "aws_instance" "elk_node6" {
  instance_type          = "r5a.xlarge"
  ami                    = data.aws_ami.server_ami.id
  key_name               = aws_key_pair.elk_auth.id
  vpc_security_group_ids = [aws_security_group.elk_sg.id]
  subnet_id              = aws_subnet.elk_public_subnet.id
  #user_data              = file("userdata.tpl")
  root_block_device {
    volume_size = 80
  }

  tags = {
    Name = "elk-node"

  }

}

resource "aws_ebs_volume" "datavol_node6" {
  availability_zone = aws_instance.elk_node6.availability_zone
  size              = 1500
  tags = {
    Name = "data-volume"
  }
}
resource "aws_volume_attachment" "elk_data_vol_attach_node6" {
  device_name = "/dev/sdd"
  volume_id   = aws_ebs_volume.datavol_node6.id
  instance_id = aws_instance.elk_node6.id
}


//  Elastic node 7
resource "aws_instance" "elk_node7" {
  instance_type          = "r5a.xlarge"
  ami                    = data.aws_ami.server_ami.id
  key_name               = aws_key_pair.elk_auth.id
  vpc_security_group_ids = [aws_security_group.elk_sg.id]
  subnet_id              = aws_subnet.elk_public_subnet.id
  #user_data              = file("userdata.tpl")
  root_block_device {
    volume_size = 80
  }

  tags = {
    Name = "elk-node"

  }

}

resource "aws_ebs_volume" "datavol_node7" {
  availability_zone = aws_instance.elk_node7.availability_zone
  size              = 1500
  tags = {
    Name = "data-volume"
  }
}
resource "aws_volume_attachment" "elk_data_vol_attach_node7" {
  device_name = "/dev/sdd"
  volume_id   = aws_ebs_volume.datavol_node7.id
  instance_id = aws_instance.elk_node7.id
}


//  Elastic node 8
resource "aws_instance" "elk_node8" {
  instance_type          = "r5a.xlarge"
  ami                    = data.aws_ami.server_ami.id
  key_name               = aws_key_pair.elk_auth.id
  vpc_security_group_ids = [aws_security_group.elk_sg.id]
  subnet_id              = aws_subnet.elk_public_subnet.id
  #user_data              = file("userdata.tpl")
  root_block_device {
    volume_size = 80
  }

  tags = {
    Name = "elk-node"

  }

}

resource "aws_ebs_volume" "datavol_node8" {
  availability_zone = aws_instance.elk_node8.availability_zone
  size              = 1500
  tags = {
    Name = "data-volume"
  }
}
resource "aws_volume_attachment" "elk_data_vol_attach_node8" {
  device_name = "/dev/sdd"
  volume_id   = aws_ebs_volume.datavol_node8.id
  instance_id = aws_instance.elk_node8.id
}


//  Elastic node 9
resource "aws_instance" "elk_node9" {
  instance_type          = "r5a.xlarge"
  ami                    = data.aws_ami.server_ami.id
  key_name               = aws_key_pair.elk_auth.id
  vpc_security_group_ids = [aws_security_group.elk_sg.id]
  subnet_id              = aws_subnet.elk_public_subnet.id
  #user_data              = file("userdata.tpl")
  root_block_device {
    volume_size = 80
  }

  tags = {
    Name = "elk-node"

  }

}

resource "aws_ebs_volume" "datavol_node9" {
  availability_zone = aws_instance.elk_node9.availability_zone
  size              = 1500
  tags = {
    Name = "data-volume"
  }
}
resource "aws_volume_attachment" "elk_data_vol_attach_node9" {
  device_name = "/dev/sdd"
  volume_id   = aws_ebs_volume.datavol_node9.id
  instance_id = aws_instance.elk_node9.id
}


//  Elastic node 10
resource "aws_instance" "elk_node10" {
  instance_type          = "r5a.xlarge"
  ami                    = data.aws_ami.server_ami.id
  key_name               = aws_key_pair.elk_auth.id
  vpc_security_group_ids = [aws_security_group.elk_sg.id]
  subnet_id              = aws_subnet.elk_public_subnet.id
  #user_data              = file("userdata.tpl")
  root_block_device {
    volume_size = 80
  }

  tags = {
    Name = "elk-node"

  }

}

resource "aws_ebs_volume" "datavol_node10" {
  availability_zone = aws_instance.elk_node10.availability_zone
  size              = 1500
  tags = {
    Name = "data-volume"
  }
}
resource "aws_volume_attachment" "elk_data_vol_attach_node10" {
  device_name = "/dev/sdd"
  volume_id   = aws_ebs_volume.datavol_node10.id
  instance_id = aws_instance.elk_node10.id
}


resource "aws_s3_bucket" "elkbucket" {
  bucket = "901-elk-bucket"
  acl    = "private"

  tags = {
    Name        = "Elastic Search Bucket"
    Environment = "Prod"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "bucket-config" {
  bucket = aws_s3_bucket.elkbucket.bucket

  rule {
    id = "MoveToGlacier"


    status = "Enabled"

    transition {
      days          = 1
      storage_class = "GLACIER"
    }

  }
}
*/
