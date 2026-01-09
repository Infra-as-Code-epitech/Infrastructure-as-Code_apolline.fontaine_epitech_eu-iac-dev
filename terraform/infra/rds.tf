resource "aws_secretsmanager_secret" "app_config" {
  name                    = "task-manager/db-config"
  description             = "Connection details to RDS instance for app "
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "app_config_val" {
  secret_id = aws_secretsmanager_secret.app_config.id
  secret_string = jsonencode({
    host     = aws_db_instance.rds.endpoint
    port     = aws_db_instance.rds.port
    dbname   = aws_db_instance.rds.db_name
    username = aws_db_instance.rds.username
  })
}

resource "aws_db_instance" "rds" {
  region                              = var.region
  allocated_storage                   = 20
  db_name                             = "mydb"
  engine                              = "postgres"
  engine_version                      = "17.6"
  instance_class                      = "db.t4g.micro"
  manage_master_user_password         = true
  iam_database_authentication_enabled = true
  apply_immediately                   = true
  username                            = "postgres"
  skip_final_snapshot                 = true
  tags                                = var.tags
}
