provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

data "aws_secretsmanager_secret" "rds_password" {
  arn = aws_db_instance.rds.master_user_secret[0].secret_arn
}

data "aws_secretsmanager_secret_version" "rds_password" {
  secret_id = data.aws_secretsmanager_secret.rds_password.id
}

resource "kubernetes_secret" "db_credentials" {
  metadata {
    name      = "db-credentials"
    namespace = var.kubernetes_app_namespace
  }

  data = {
    DATABASE_URL = "postgresql://${aws_db_instance.rds.username}:${jsondecode(data.aws_secretsmanager_secret_version.rds_password.secret_string)["password"]}@${aws_db_instance.rds.endpoint}/${aws_db_instance.rds.db_name}"
  }

  depends_on = [aws_db_instance.rds]
}
