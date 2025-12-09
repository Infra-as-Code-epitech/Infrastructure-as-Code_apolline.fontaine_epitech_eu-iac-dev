resource "aws_db_instance" "rds" {
  allocated_storage           = 20
  db_name                     = "mydb"
  engine                      = "postgres"
  engine_version              = "17.6"
  instance_class              = "db.t4g.micro"
  manage_master_user_password = true
  username                    = "postgres"
  tags                        = var.tags
}
