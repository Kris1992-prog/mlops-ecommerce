resource "aws_security_group" "rds" {
  name        = "db-server-sg-${var.environment}"
  description = "Permetti traffico MySQL solo dal Web Server"
  vpc_id      = var.vpc_id

  ingress {
    description     = "MySQL dalla porta 3306 dal web server"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.web_security_group_id]
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
    Name        = "sg-rds-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_db_instance" "ecommerce_db" {
  allocated_storage                    = var.allocated_storage
  db_name                              = var.db_name
  engine                               = "mysql"
  engine_version                       = "8.0"
  instance_class                       = var.instance_class
  username                             = var.db_username
  password                             = var.db_password
  parameter_group_name                 = "default.mysql8.0"
  storage_encrypted                    = true
  backup_retention_period             = var.db_backup_retention_days
  publicly_accessible                 = false
  deletion_protection                 = false
  iam_database_authentication_enabled = true
  skip_final_snapshot                 = true

  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [aws_security_group.rds.id]

  tags = {
    Name        = "rds-mysql-${var.environment}"
    Environment = var.environment
  }
}