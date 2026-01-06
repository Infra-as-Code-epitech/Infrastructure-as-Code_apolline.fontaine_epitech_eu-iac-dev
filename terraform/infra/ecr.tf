resource "aws_ecr_repository" "infra" {
  name                 = "github-runners"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "github-runners"
    Environment = var.env
  }
}

resource "aws_ecr_lifecycle_policy" "infra_policy" {
  repository = aws_ecr_repository.infra.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

resource "null_resource" "docker_build_push" {
  triggers = {
    dockerfile_hash = filemd5("${path.module}/Dockerfile")
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Login ECR
      aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${aws_ecr_repository.infra.repository_url}
      
      # Build l'image
      docker build -t ${aws_ecr_repository.infra.repository_url}:${var.image_tag} ${path.module}
      
      # Push l'image
      docker push ${aws_ecr_repository.infra.repository_url}:${var.image_tag}
    EOT
  }

  depends_on = [aws_ecr_repository.infra]
}

