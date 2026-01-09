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

resource "aws_db_subnet_group" "rds" {
  name       = "rds"
  subnet_ids = module.vpc.private_subnets
  tags       = var.tags
}

resource "aws_security_group" "rds" {
  name_prefix = "rds-sg"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.rds.id
  from_port         = 5432
  ip_protocol       = "tcp"
  to_port           = 5432
}

resource "aws_db_instance" "rds" {
  region                              = var.region
  allocated_storage                   = 20
  db_name                             = "mydb"
  engine                              = "postgres"
  engine_version                      = "17.6"
  instance_class                      = "db.t4g.micro"
  db_subnet_group_name                = aws_db_subnet_group.rds.name
  vpc_security_group_ids              = module.vpc.default_security_group_id
  manage_master_user_password         = true
  iam_database_authentication_enabled = true
  apply_immediately                   = true
  username                            = "postgres"
  skip_final_snapshot                 = true
  tags                                = var.tags
}
