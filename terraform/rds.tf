# =============================================================================
# DATABASE: AWS RDS POSTGRESQL 16
# =============================================================================

# DB Subnet Group placing the database into private isolated subnets
resource "aws_db_subnet_group" "db_subnets" {
  name        = "${var.project_name}-${var.environment}-db-subnet-group"
  description = "Private subnets for Rice URL Shortener PostgreSQL instance"
  subnet_ids  = aws_subnet.private[*].id

  tags = {
    Name = "${var.project_name}-${var.environment}-db-subnet-group"
  }
}

# PostgreSQL Database Instance
resource "aws_db_instance" "postgres" {
  identifier            = "${var.project_name}-${var.environment}-db"
  engine                = "postgres"
  engine_version        = "16"
  instance_class        = var.db_instance_class
  allocated_storage     = 20
  max_allocated_storage = 100 # Automatically scale storage as link data grows

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.db_subnets.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  multi_az                  = var.multi_az_db
  publicly_accessible       = false # Never expose database directly to internet
  storage_encrypted         = true
  deletion_protection       = false
  skip_final_snapshot       = true
  final_snapshot_identifier = "${var.project_name}-${var.environment}-final-snapshot"

  backup_retention_period = 1             # Maximum allowed for AWS Free Tier accounts
  backup_window           = "03:00-04:00" # UTC (overnight)
  maintenance_window      = "Sun:04:30-Sun:05:30"

  tags = {
    Name = "${var.project_name}-${var.environment}-postgresql"
  }
}
