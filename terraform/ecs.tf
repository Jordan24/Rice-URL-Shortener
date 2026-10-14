# =============================================================================
# COMPUTE: AWS ECS FARGATE & ECR REPOSITORY
# =============================================================================

# Elastic Container Registry (ECR) for storing Docker container images
resource "aws_ecr_repository" "server" {
  name                 = "${var.project_name}-server"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-ecr"
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.environment}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# CloudWatch Log Group for container logs
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.project_name}-${var.environment}"
  retention_in_days = 30
}

# IAM Role for ECS Task Execution (pulling images, writing logs)
resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.project_name}-${var.environment}-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Definition (Fargate)
resource "aws_ecs_task_definition" "server" {
  family                   = "${var.project_name}-${var.environment}-server"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.backend_cpu
  memory                   = var.backend_memory
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "serverpod"
      image     = "${aws_ecr_repository.server.repository_url}:latest"
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        },
        {
          containerPort = var.redirect_port
          hostPort      = var.redirect_port
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "SERVERPOD_DATABASE_HOST"
          value = aws_db_instance.postgres.address
        },
        {
          name  = "SERVERPOD_DATABASE_PORT"
          value = "5432"
        },
        {
          name  = "SERVERPOD_DATABASE_NAME"
          value = var.db_name
        },
        {
          name  = "SERVERPOD_DATABASE_USER"
          value = var.db_username
        },
        {
          name  = "SERVERPOD_DATABASE_PASSWORD"
          value = var.db_password
        },
        {
          name  = "SERVERPOD_SERVICE_SECRET"
          value = sha256("${var.db_password}-${var.project_name}-secret")
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "serverpod"
        }
      }
    }
  ])
}

# ECS Service maintaining running container replicas
resource "aws_ecs_service" "main" {
  name            = "${var.project_name}-${var.environment}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.server.arn
  desired_count   = var.backend_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.redirect.arn
    container_name   = "serverpod"
    container_port   = var.redirect_port
  }

  depends_on = [aws_lb_listener.http]
}

