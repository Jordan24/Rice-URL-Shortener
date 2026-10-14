# =============================================================================
# SECURITY GROUPS: PRINCIPLE OF LEAST PRIVILEGE
# =============================================================================

# 1. Application Load Balancer Security Group
# Accepts HTTP and HTTPS from the public internet
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Controls inbound web traffic to the ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow inbound HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow inbound HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound to VPC for forwarding to ECS tasks"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-alb-sg"
  }
}

# 2. ECS Fargate Backend Tasks Security Group
# ONLY accepts connections from the ALB security group
resource "aws_security_group" "ecs_sg" {
  name        = "${var.project_name}-${var.environment}-ecs-sg"
  description = "Allows inbound traffic only from the ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow Serverpod API traffic from ALB"
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    description     = "Allow Serverpod Redirect/Health traffic from ALB"
    from_port       = var.redirect_port
    to_port         = var.redirect_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    description = "Allow outbound to internet and database"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-ecs-sg"
  }
}

# 3. RDS PostgreSQL Database Security Group
# STRICTLY accepts connections on port 5432 ONLY from the ECS Backend Security Group
resource "aws_security_group" "db_sg" {
  name        = "${var.project_name}-${var.environment}-db-sg"
  description = "Allows PostgreSQL traffic strictly from ECS backend tasks"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL from ECS backend tasks only"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sg.id]
  }

  egress {
    description = "No outbound required for private database"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-db-sg"
  }
}

