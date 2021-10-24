# ========== Provider ==============================================
# ==================================================================
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = "eu-west-2"
  
  }

# ========== VPC ===================================================
# ==================================================================
resource "aws_vpc" "vpc-01" {
  cidr_block = "10.10.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "EPAM_AWS_TF_Course_vpc-01"
  }
}

# ========== Internet gateway =======================================
# ==================================================================
resource "aws_internet_gateway" "wp_igw" {
  vpc_id = aws_vpc.vpc-01.id

  tags = {
    Name = "EPAM_AWS_TF_Course_vpc-01_igw"
  }
}

# ========== Route to IGW =======================================
# ==================================================================
resource "aws_route" "route_to_igw" {
  route_table_id            = aws_vpc.vpc-01.default_route_table_id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.wp_igw.id
  depends_on                = [aws_internet_gateway.wp_igw, aws_vpc.vpc-01]
}

# ========== Subnets ===============================================
# ==================================================================
resource "aws_subnet" "subnet-01" {
  vpc_id = aws_vpc.vpc-01.id
  cidr_block = "10.10.10.0/24"
  availability_zone = "eu-west-2a"
  
  tags = {
    Name = "EPAM_AWS_TF_Course_subnet-01"
    }
  }

resource "aws_subnet" "subnet-02" {
  vpc_id = aws_vpc.vpc-01.id
  cidr_block = "10.10.20.0/24"
  availability_zone = "eu-west-2b"
  
  tags = {
    Name = "EPAM_AWS_TF_Course_subnet-02"
    }
  }

resource "aws_db_subnet_group" "wp_db_subnet_group" {
  name       = "wp-db-subnet-group"
  subnet_ids = [aws_subnet.subnet-01.id, aws_subnet.subnet-02.id]

  tags = {
    Name = "EPAM_AWS_TF_Course_db_subnet_group"
  }
}

# ========== ELB ===================================================
# ==================================================================
resource "aws_elb" "wp_lb" {
  name               = "wp-lb"
  internal = false
  subnets = [aws_subnet.subnet-01.id, aws_subnet.subnet-02.id]
#   availability_zones = ["eu-west-2a", "eu-west-2b"]
#   subnets = [aws_subnet.subnet-01.id, aws_subnet.subnet-02.id]
  security_groups = [aws_security_group.wp_elb_sg.id]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    target              = "HTTP:80/readme.html"
    interval            = 10
    
  }

  instances                   = [aws_instance.wp_inst-01.id, aws_instance.wp_inst-02.id]
  cross_zone_load_balancing   = false
  connection_draining         = true
  connection_draining_timeout = 120

  tags = {
    Name = "EPAM_AWS_TF_Course_wp_lb"
  }
}

# ========== ELB security group ====================================
# ==================================================================
resource "aws_security_group" "wp_elb_sg" {
  name = "wp_elb_sg"
  vpc_id = aws_vpc.vpc-01.id

  ingress = [
    {
      description = "Allow HTTP."
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids = []
      security_groups = []
      self = false
    }
  ]

  egress = [
    {
    description = "Allow all outgoing traffic."
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
    prefix_list_ids = []
    security_groups = []
    self = false      
    },
  ]

  tags = {
    Name = "EPAM_AWS_TF_Course_wp_elb_sg"
    }
}

# ========== EFS ===================================================
# ==================================================================
resource "aws_efs_file_system" "efs_for_wp" {
  
  tags = {
    Name = "EPAM_AWS_TF_Course_efs_for_wp"
    }
  }

resource "aws_efs_mount_target" "efs_mount_target_wp_inst-01" {
  file_system_id = aws_efs_file_system.efs_for_wp.id
  subnet_id = aws_subnet.subnet-01.id
  security_groups = [aws_security_group.wp_efs_sg.id]
  }

resource "aws_efs_mount_target" "efs_mount_target_wp_inst-02" {
  file_system_id = aws_efs_file_system.efs_for_wp.id
  subnet_id = aws_subnet.subnet-02.id
  security_groups = [aws_security_group.wp_efs_sg.id]
}

# ========== EFS security group ==============================
# ==================================================================
resource "aws_security_group" "wp_efs_sg" {
  name = "wp_efs_sg"
  vpc_id = aws_vpc.vpc-01.id

  ingress = [
    {
      description = "Allow private NFS."
      from_port = 2049
      to_port = 2049
      protocol = "tcp"
      cidr_blocks = [aws_vpc.vpc-01.cidr_block]
      ipv6_cidr_blocks = []
      prefix_list_ids = []
      security_groups = []
      self = false
    },
  ]

  egress = [
    {
    description = "Allow all outgoing private traffic."
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [aws_vpc.vpc-01.cidr_block]
    ipv6_cidr_blocks = []
    prefix_list_ids = []
    security_groups = []
    self = false      
    },
  ]

  tags = {
    Name = "EPAM_AWS_TF_Course_wp_efs_sg"
    }
}

# ========== DB instance ===========================================
# ==================================================================
resource "aws_db_instance" "wp_db" {
  identifier = "wp-db"
  engine = "mysql"
  engine_version = "5.7.34"
  allocated_storage = 20
  instance_class = "db.t2.micro"
  vpc_security_group_ids = [aws_security_group.wp_db_sg.id]
  availability_zone = "eu-west-2a"
  db_subnet_group_name = aws_db_subnet_group.wp_db_subnet_group.id
  name = var.db_name
  username = var.db_user
  password = var.db_password
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot = true
  depends_on = [aws_efs_file_system.efs_for_wp]
   
  tags = {
      Name = "EPAM_AWS_TF_Course_wp_db"
  }
}

# ========== DB security group ==============================
# ==================================================================
resource "aws_security_group" "wp_db_sg" {
  name = "wp_db_sg"
  vpc_id = aws_vpc.vpc-01.id

  ingress = [
    {
      description = "Allow private SQL."
      from_port = 3306
      to_port = 3306
      protocol = "tcp"
      cidr_blocks = [aws_vpc.vpc-01.cidr_block]
      ipv6_cidr_blocks = []
      prefix_list_ids = []
      security_groups = []
      self = false
    }
  ]

  egress = [
    {
    description = "Allow all outgoing private traffic."
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [aws_vpc.vpc-01.cidr_block]
    ipv6_cidr_blocks = []
    prefix_list_ids = []
    security_groups = []
    self = false      
    }
  ]

  tags = {
    Name = "EPAM_AWS_TF_Course_wp_db_sg"
    }
}

# ========== Instances =============================================
# ==================================================================

data "template_file" "init_cfg" {
  template = file("./cloud-init.yaml")
  vars = {
    "aws_efs_dns_name" = "${aws_efs_file_system.efs_for_wp.dns_name}"
    "db_name" = "${var.db_name}"
    "db_user" = "${var.db_user}"
    "db_password" = "${var.db_password}"
    "db_host" = "${aws_db_instance.wp_db.address}"
  }
}

data "template_cloudinit_config" "cloudinit_cfg" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "./cloud-init.yaml"
    content_type = "text/cloud-config"
    content      = data.template_file.init_cfg.rendered
  }

  # part {
  #   content_type = "text/x-shellscript"
  #   content      = data.template_file.shell-script.rendered
  # }
}

resource "aws_instance" "wp_inst-01" {
  ami = "ami-08095fbc7037048f3"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.wp_inst_sg.id]
  subnet_id = aws_subnet.subnet-01.id
  associate_public_ip_address = true
  key_name = var.key_name
  depends_on = [aws_db_instance.wp_db]

  user_data = data.template_cloudinit_config.cloudinit_cfg.rendered
  
  tags = {
    Name = "EPAM_AWS_TF_Course_wp_inst-01"
    }
}

resource "aws_instance" "wp_inst-02" {
  ami = "ami-08095fbc7037048f3"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.wp_inst_sg.id]
  subnet_id = aws_subnet.subnet-02.id
  associate_public_ip_address = true
  key_name = var.key_name
  depends_on = [aws_db_instance.wp_db]
  
  user_data = data.template_cloudinit_config.cloudinit_cfg.rendered

  tags = {
    Name = "EPAM_AWS_TF_Course_wp_inst-02"
    }
}

# ========== Instances security group ==============================
# ==================================================================
resource "aws_security_group" "wp_inst_sg" {
  name = "wp_inst_sg"
  vpc_id = aws_vpc.vpc-01.id

  ingress = [
    {
      # ===== SSH =====
      description = "Allow SSH - IPv4."
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["185.44.13.36/32", "95.165.8.101/32"]
      ipv6_cidr_blocks = []
      prefix_list_ids = []
      security_groups = []
      self = false      
    },

    {
      description = "Allow HTTP - IPv4."
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["10.10.0.0/16", "185.44.13.36/32", "95.165.8.101/32"]
      ipv6_cidr_blocks = []
      prefix_list_ids = []
      security_groups = []
      self = false
    },

    {
      description = "Allow HTTP - IPv4."
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["10.10.0.0/16", "185.44.13.36/32", "95.165.8.101/32"]
      ipv6_cidr_blocks = []
      prefix_list_ids = []
      security_groups = []
      self = false
    }
  ]

  egress = [
    {
    description = "Allow all outgoing traffic."
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
    prefix_list_ids = []
    security_groups = []
    self = false      
    },
  ]

  tags = {
    Name = "EPAM_AWS_TF_Course_wp_inst_sg"
    }
}