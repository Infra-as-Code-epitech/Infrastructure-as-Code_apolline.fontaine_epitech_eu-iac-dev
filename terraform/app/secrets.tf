provider "kubernetes" {
  host                   = data.terraform_remote_state.infra.outputs.eks_endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.infra.outputs.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

data "aws_secretsmanager_secret" "db_config" {
  name = "task-manager/db-config"
}

data "aws_secretsmanager_secret_version" "db_config" {
  secret_id = data.aws_secretsmanager_secret.db_config.id
}

data "aws_secretsmanager_secret" "rds_password" {
  name = data.terraform_remote_state.infra.outputs.rds_master_secret_name
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
    DATABASE_URL = "postgresql://${jsondecode(data.aws_secretsmanager_secret_version.db_config.secret_string)["username"]}:${jsondecode(data.aws_secretsmanager_secret_version.rds_password.secret_string)["password"]}@${jsondecode(data.aws_secretsmanager_secret_version.db_config.secret_string)["host"]}/${jsondecode(data.aws_secretsmanager_secret_version.db_config.secret_string)["dbname"]}"
  }
}
