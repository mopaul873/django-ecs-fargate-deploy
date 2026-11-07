locals {
  container_name = "web"
  allowed_hosts  = join(",", compact([aws_lb.main.dns_name, var.domain_name]))
  csrf_origins = join(",", compact([
    var.domain_name != "" ? "https://${var.domain_name}" : "",
    "http://${aws_lb.main.dns_name}",
  ]))
}

resource "aws_ecs_cluster" "main" {
  name = "${local.name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${local.name}"
  retention_in_days = 30
}

# Initial task definition. GitHub Actions registers new revisions on every deploy
# (same settings, new image tag), so Terraform ignores later changes in the service.
resource "aws_ecs_task_definition" "app" {
  family                   = local.name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([{
    name      = local.container_name
    image     = "${aws_ecr_repository.app.repository_url}:${var.image_tag}"
    essential = true

    portMappings = [{
      containerPort = var.container_port
      protocol      = "tcp"
    }]

    environment = [
      { name = "DJANGO_DEBUG", value = "false" },
      { name = "DJANGO_ALLOWED_HOSTS", value = local.allowed_hosts },
      { name = "DJANGO_CSRF_TRUSTED_ORIGINS", value = local.csrf_origins },
      { name = "DJANGO_SECURE_COOKIES", value = tostring(local.https_enabled) },
      { name = "DB_HOST", value = aws_db_instance.main.address },
      { name = "DB_PORT", value = tostring(aws_db_instance.main.port) },
      { name = "DB_NAME", value = aws_db_instance.main.db_name },
      { name = "APP_VERSION", value = var.image_tag },
    ]

    # Pulled from Secrets Manager at task start (":username::" picks a key from the JSON secret)
    secrets = [
      { name = "DJANGO_SECRET_KEY", valueFrom = aws_secretsmanager_secret.django_secret_key.arn },
      { name = "DB_USER", valueFrom = "${aws_db_instance.main.master_user_secret[0].secret_arn}:username::" },
      { name = "DB_PASSWORD", valueFrom = "${aws_db_instance.main.master_user_secret[0].secret_arn}:password::" },
    ]

    healthCheck = {
      command     = ["CMD-SHELL", "python -c \"import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://localhost:${var.container_port}/health/').status==200 else 1)\""]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 30
    }

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.app.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "web"
      }
    }

    # ECS sends SIGTERM, waits this long, then SIGKILL - gunicorn finishes requests in between
    stopTimeout = 30
  }])
}

resource "aws_ecs_service" "app" {
  name             = "${local.name}-service"
  cluster          = aws_ecs_cluster.main.id
  task_definition  = aws_ecs_task_definition.app.arn
  desired_count    = var.desired_count
  launch_type      = "FARGATE"
  platform_version = "LATEST"

  # ---- Zero-downtime rolling deployment ----
  # 100% = never drop below the current number of healthy tasks
  # 200% = start the full set of new tasks before old ones are stopped
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  # If new tasks keep failing health checks, stop the deployment and roll back automatically
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  # Don't let the ALB kill tasks while Django is still starting
  health_check_grace_period_seconds = 60

  enable_execute_command = true

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = local.container_name
    container_port   = var.container_port
  }

  # GitHub Actions owns the task definition revision; autoscaling owns desired_count
  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  depends_on = [aws_lb_listener.http]
}
