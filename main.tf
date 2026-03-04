resource "aws_vpc" "lamp_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "lamp-vpc"
  }
}

resource "aws_subnet" "lamp_public_subnet" {
  vpc_id                  = aws_vpc.lamp_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "lamp-public-subnet"
  }
}

resource "aws_subnet" "lamp_private_subnet" {
  vpc_id                  = aws_vpc.lamp_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = false

  tags = {
    Name = "lamp-private-subnet"
  }
}

resource "aws_internet_gateway" "lamp_igw" {
  vpc_id = aws_vpc.lamp_vpc.id

  tags = {
    Name = "lamp-igw"
  }
}

resource "aws_route_table" "lamp_public_rt" {
  vpc_id = aws_vpc.lamp_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lamp_igw.id
  }

  tags = {
    Name = "lamp-public-rt"
  }
}

resource "aws_route_table_association" "lamp_public_assoc" {
  subnet_id      = aws_subnet.lamp_public_subnet.id
  route_table_id = aws_route_table.lamp_public_rt.id
}

resource "aws_route_table" "lamp_private_rt" {
  vpc_id = aws_vpc.lamp_vpc.id

  tags = {
    Name = "lamp-private-rt"
  }
}

resource "aws_route_table_association" "lamp_private_assoc" {
  subnet_id      = aws_subnet.lamp_private_subnet.id
  route_table_id = aws_route_table.lamp_private_rt.id
}

locals {
  mysql_app_password_sql = replace(var.mysql_app_password, "'", "''")

  web_user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail

    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get install -y docker.io mysql-client curl nginx amazon-ssm-agent || apt-get install -y docker.io mysql-client curl nginx

    systemctl enable docker
    systemctl restart docker
    systemctl enable amazon-ssm-agent || true
    systemctl restart amazon-ssm-agent || true

    usermod -aG docker ubuntu || true

    docker pull ${var.docker_image}
    docker rm -f ${var.app_container_name} || true

    cat > /opt/lamp-app.env <<'ENVEOF'
    DB_HOST=${aws_instance.lamp_db_server.private_ip}
    DB_PORT=3306
    DB_NAME=${var.mysql_database}
    DB_USER=${var.mysql_app_user}
    DB_PASSWORD=${var.mysql_app_password}
    FLASK_ENV=${var.flask_env}
    ENVEOF

    chown root:root /opt/lamp-app.env
    chmod 600 /opt/lamp-app.env

    docker run -d \
      --name ${var.app_container_name} \
      --restart unless-stopped \
      -p ${var.app_host_port}:${var.app_container_port} \
      --env-file /opt/lamp-app.env \
      ${var.docker_image}

    cat > /etc/nginx/sites-available/lamp-app <<'NGINXCONF'
    server {
      listen 80;
      server_name _;

      location / {
        proxy_pass http://127.0.0.1:${var.app_host_port};
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_connect_timeout 60s;
        proxy_read_timeout 60s;
      }
    }
    NGINXCONF

    rm -f /etc/nginx/sites-enabled/default
    ln -sfn /etc/nginx/sites-available/lamp-app /etc/nginx/sites-enabled/lamp-app

    nginx -t
    systemctl enable nginx
    systemctl restart nginx
  EOF

  db_user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail

    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get install -y mysql-server

    MYSQL_CNF="/etc/mysql/mysql.conf.d/mysqld.cnf"
    if [ -f "$MYSQL_CNF" ]; then
      sed -i 's/^bind-address\s*=.*/bind-address = 0.0.0.0/' "$MYSQL_CNF"
    fi

    systemctl enable mysql
    systemctl restart mysql

    mysql --protocol=socket <<SQL
    DELETE FROM mysql.user WHERE User='';
    DROP DATABASE IF EXISTS test;
    DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
    CREATE DATABASE IF NOT EXISTS ${var.mysql_database};
    CREATE USER IF NOT EXISTS '${var.mysql_app_user}'@'${var.mysql_app_host}' IDENTIFIED BY '${local.mysql_app_password_sql}';
    ALTER USER '${var.mysql_app_user}'@'${var.mysql_app_host}' IDENTIFIED BY '${local.mysql_app_password_sql}';
    GRANT ALL PRIVILEGES ON ${var.mysql_database}.* TO '${var.mysql_app_user}'@'${var.mysql_app_host}';
    FLUSH PRIVILEGES;
    SQL

    mysql --protocol=socket ${var.mysql_database} <<SQL
    CREATE TABLE IF NOT EXISTS visitors (
      id INT AUTO_INCREMENT PRIMARY KEY,
      visited_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    INSERT INTO visitors () VALUES ();
    SQL
  EOF
}

resource "aws_security_group" "lamp_web_sg" {
  name        = "lamp-web-sg"
  description = "Security group for web server"
  vpc_id      = aws_vpc.lamp_vpc.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH for CI/CD deploy"
    from_port   = 22
    to_port     = 22
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
    Name = "lamp-web-sg"
  }
}

resource "aws_security_group" "lamp_db_sg" {
  name        = "lamp-db-sg"
  description = "Security group for MySQL database"
  vpc_id      = aws_vpc.lamp_vpc.id

  ingress {
    description     = "MySQL from web security group"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.lamp_web_sg.id]
  }

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "lamp-db-sg"
  }
}

resource "tls_private_key" "lamp_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_sensitive_file" "lamp_key_pem" {
  content         = tls_private_key.lamp_key.private_key_pem
  filename        = "${path.module}/lamp-key.pem"
  file_permission = "0400"
}

resource "aws_key_pair" "lamp_key" {
  key_name   = "lamp-key"
  public_key = tls_private_key.lamp_key.public_key_openssh

  tags = {
    Name = "lamp-key"
  }
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lamp_web_ssm_role" {
  name               = "lamp-web-ssm-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = {
    Name = "lamp-web-ssm-role"
  }
}

resource "aws_iam_role_policy_attachment" "lamp_web_ssm_core" {
  role       = aws_iam_role.lamp_web_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "lamp_web_instance_profile" {
  name = "lamp-web-instance-profile"
  role = aws_iam_role.lamp_web_ssm_role.name
}

data "aws_ssm_parameter" "ubuntu_2404_ami" {
  name = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

resource "aws_instance" "lamp_web_server" {
  ami                         = data.aws_ssm_parameter.ubuntu_2404_ami.value
  instance_type               = var.instance_type
  availability_zone           = var.availability_zone
  subnet_id                   = aws_subnet.lamp_public_subnet.id
  vpc_security_group_ids      = [aws_security_group.lamp_web_sg.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.lamp_key.key_name
  iam_instance_profile        = aws_iam_instance_profile.lamp_web_instance_profile.name
  user_data                   = local.web_user_data
  user_data_replace_on_change = true

  depends_on = [aws_instance.lamp_db_server]

  tags = {
    Name = "lamp-web-server"
  }
}

resource "aws_instance" "lamp_db_server" {
  ami                         = data.aws_ssm_parameter.ubuntu_2404_ami.value
  instance_type               = var.instance_type
  availability_zone           = var.availability_zone
  subnet_id                   = aws_subnet.lamp_private_subnet.id
  vpc_security_group_ids      = [aws_security_group.lamp_db_sg.id]
  associate_public_ip_address = false
  key_name                    = aws_key_pair.lamp_key.key_name
  user_data                   = local.db_user_data
  user_data_replace_on_change = true

  tags = {
    Name = "lamp-db-server"
  }
}
