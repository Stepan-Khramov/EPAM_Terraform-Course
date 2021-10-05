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

  tags = {
    Name = "EPAM_AWS_TF_Course_vpc-01"
  }
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

# ========== Network interfaces======================================
# ==================================================================
resource "aws_network_interface" "wp_inst-01_ntwk_int" {
  subnet_id = aws_subnet.subnet-01.id
  private_ip = "10.10.10.10"

  attachment {
    instance = "wp_inst-01"
    device_index = 0
  }
  tags = {
    Name = "EPAM_AWS_TF_Course_wp_inst_1_ntwk_int"
  }
}

resource "aws_network_interface" "wp_inst-02_ntwk_int" {
  subnet_id = aws_subnet.subnet-02.id
  private_ip = "10.10.20.10"

  attachment {
    instance = "wp_inst-02"
    device_index = 0
  }
  tags = {
    Name = "EPAM_AWS_TF_Course_wp_inst_2_ntwk_int"
  }
}

# ========== EFS ===================================================
# ==================================================================
resource "aws_efs_file_system" "efs_for_wp_db" {
  
  tags = {
    Name = "EPAM_AWS_TF_Course_efs_for_wp_db"
    }
  }

resource "aws_efs_mount_target" "efs_mount_target_wp_inst-01" {
  file_system_id = aws_efs_file_system.efs_for_wp_db.id
  subnet_id = aws_subnet.subnet-01.id
  }

resource "aws_efs_mount_target" "efs_mount_target_wp_inst-02" {
  file_system_id = aws_efs_file_system.efs_for_wp_db.id
  subnet_id = aws_subnet.subnet-02.id
}

resource "aws_db_instance" "wp_db" {
  identifier = "wp-db"
  engine = "mysql"
  engine_version = "5.7"
  allocated_storage = 10
  instance_class = "db.t2.micro"
  vpc_security_group_ids = [aws_security_group.wp_sg.id]
  name = "wp_db"
  username = "dbadmin"
  password = "dbpassword"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot = true
   
  tags = {
      Name = "wp_db"
  }
}

# ========== Security group ===================================================
# ==================================================================
resource "aws_security_group" "wp_sg" {
  name = "wp_sg"
  vpc_id = aws_vpc.vpc-01.id

  ingress = [
    {
      # ===== SSH =====
      description = "Allow SSH."
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
      description = "Allow HTTP."
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids = []
      security_groups = []
      self = false
    },

    {
      description = "Allow SQL."
      from_port = 3306
      to_port = 3306
      protocol = "tcp"
      cidr_blocks = [aws_vpc.vpc-01.cidr_block]
      ipv6_cidr_blocks = []
      prefix_list_ids = []
      security_groups = []
      self = false
    },

    {
      description = "Allow NFS."
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
    description = "Allow all outgoing traffic."
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
    Name = "wp_sg"
    }
}

#  resource "aws_vpc_endpoint" "vpc-01_endpoint" {

# }

# ========== Instances =============================================
# ==================================================================
resource "aws_instance" "wp_inst-01" {
  ami = "ami-0c2d06d50ce30b442"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.wp_sg.id]
  key_name = var.key_name
  ebs_block_device {
    device_name = "/dev/sdb"
    volume_size = "10"
    delete_on_termination = "true"
    }

  user_data = <<EOF
        #!/bin/bash
        echo "${aws_efs_file_system.efs_for_wp_db.dns_name}:/ /var/www/html nfs defaults,vers=4.1 0 0" >> /etc/fstab
        dnf install -y httpd httpd-tools php php-cli php-json php-gd php-mbstring php-pdo php-xml php-mysqlnd php-pecl-zip wget
        cd /tmp
        wget https://www.wordpress.org/latest.tar.gz
        mount -a
        mkdir /var/www/html
        tar xzvf /tmp/latest.tar.gz --strip 1 -C /var/www/html
        rm /tmp/latest.tar.gz
        chown -Rf apache:apache /var/www/html
        chmod -Rf 775 /var/www/html
        systemctl enable httpd
        sed -i 's/#ServerName www.example.com:80/ServerName web1.darhar-net.com:80/' /etc/httpd/conf/httpd.conf
        sed -i 's/ServerAdmin root@localhost/ServerAdmin admin@web1.darhar-net.com/' /etc/httpd/conf/httpd.conf
        sed -i 's/SELINUX=disabled/SELINUX=enforcing/' /etc/selinux/config
        semanage fcontext -a -t httpd_sys_rw_content_t "/var/www/html(/.*)?"
        restorecon -Rv /var/www/html
        setsebool -P httpd_can_network_connect 1
        setsebool -P httpd_can_network_connect_db 1
        systemctl start httpd
        firewall-cmd --zone=public --permanent --add-service=http
        firewall-cmd --reload
        iptables -A INPUT -p tcp --dport 80 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
        iptables -A OUTPUT -p tcp --sport 80 -m conntrack --ctstate ESTABLISHED -j ACCEPT
    EOF

  tags = {
    Name = "EPAM_AWS_TF_Course_wp_inst-01"
    }
}

resource "aws_instance" "wp_inst-02" {
  ami = "ami-0c2d06d50ce30b442"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.wp_sg.id]
  key_name = var.key_name
  ebs_block_device {
    device_name = "/dev/sdb"
    volume_size = "10"
    delete_on_termination = "true"
    }

  user_data = <<EOF
        #!/bin/bash
        echo "${aws_efs_file_system.efs_for_wp_db.dns_name}:/ /var/www/html nfs defaults,vers=4.1 0 0" >> /etc/fstab
        dnf install -y httpd httpd-tools php php-cli php-json php-gd php-mbstring php-pdo php-xml php-mysqlnd php-pecl-zip wget
        cd /tmp
        wget https://www.wordpress.org/latest.tar.gz
        mount -a
        mkdir /var/www/html
        tar xzvf /tmp/latest.tar.gz --strip 1 -C /var/www/html
        rm /tmp/latest.tar.gz
        chown -Rf apache:apache /var/www/html
        chmod -Rf 775 /var/www/html
        systemctl enable httpd
        sed -i 's/#ServerName www.example.com:80/ServerName web1.darhar-net.com:80/' /etc/httpd/conf/httpd.conf
        sed -i 's/ServerAdmin root@localhost/ServerAdmin admin@web1.darhar-net.com/' /etc/httpd/conf/httpd.conf
        sed -i 's/SELINUX=disabled/SELINUX=enforcing/' /etc/selinux/config
        semanage fcontext -a -t httpd_sys_rw_content_t "/var/www/html(/.*)?"
        restorecon -Rv /var/www/html
        setsebool -P httpd_can_network_connect 1
        setsebool -P httpd_can_network_connect_db 1
        systemctl start httpd
        firewall-cmd --zone=public --permanent --add-service=http
        firewall-cmd --reload
        iptables -A INPUT -p tcp --dport 80 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
        iptables -A OUTPUT -p tcp --sport 80 -m conntrack --ctstate ESTABLISHED -j ACCEPT
    EOF

  tags = {
    Name = "EPAM_AWS_TF_Course_wp_inst-02"
    }
}




