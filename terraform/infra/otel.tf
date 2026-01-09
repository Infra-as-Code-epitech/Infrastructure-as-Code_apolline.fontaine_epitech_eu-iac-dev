resource "aws_iam_role" "otel_collector" {
  name = "otel-collector-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "otel_cloudwatch" {
  role       = aws_iam_role.otel_collector.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_ecs_cluster" "otel_cluster" {
  name = "otel-collector-cluster"
}

resource "aws_ecs_task_definition" "otel_collector" {
  family                   = "otel-collector"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.otel_collector.arn
  task_role_arn            = aws_iam_role.otel_collector.arn

  container_definitions = jsonencode([{
    name  = "otel-collector"
    image = "otel/opentelemetry-collector-contrib:latest"
    
    environment = [
      {
        name  = "DB_HOST"
        value = aws_db_instance.postgres.address
      },
      {
        name  = "DB_PORT"
        value = "5432"
      }
    ]
    
    secrets = [
      {
        name      = "DB_PASSWORD"
        valueFrom = aws_secretsmanager_secret.db_password.arn
      }
    ]
    
    portMappings = [{
      containerPort = 4317
      protocol      = "tcp"
    }]
    
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.otel_collector.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "otel"
      }
    }
    
    mountPoints = [{
      sourceVolume  = "otel-config"
      containerPath = "/etc/otel"
      readOnly      = true
    }]
    
    command = ["--config=/etc/otel/config.yaml"]
  }])

  volume {
    name = "otel-config"
    
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.otel_config.id
      root_directory = "/"
    }
  }
}
