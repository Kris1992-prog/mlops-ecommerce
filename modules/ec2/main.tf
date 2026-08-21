data "aws_ami" "ubuntu_latest" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

data "aws_eip" "ip_permanente" {
  public_ip = var.elastic_ip
}

resource "aws_security_group" "web_sg" {
  name        = "web-server-sg-${var.environment}"
  description = "Permetti traffico HTTP e SSH"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP pubblico"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH accesso ristretto all IP dell amministratore"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  egress {
    description = "Tutto il traffico in uscita"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "sg-web-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_instance" "mio_primo_server" {
  subnet_id              = var.public_subnet_id
  ami                    = data.aws_ami.ubuntu_latest.id
  instance_type          = var.instance_type
  key_name               = var.ec2_key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  monitoring = true

  metadata_options {
    http_tokens = "required" # IMDSv2 obbligatorio
  }

  root_block_device {
    encrypted = true
  }

  user_data = templatefile("${path.module}/userdata.sh.tpl", {
    db_host  = var.db_host
    db_user  = var.db_username
    db_pass  = var.db_password
    db_name  = var.db_name
    app_repo = var.app_repo_url
  })

  tags = {
    Name        = "Server-Kris-Terraform-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.mio_primo_server.id
  allocation_id = data.aws_eip.ip_permanente.id
}