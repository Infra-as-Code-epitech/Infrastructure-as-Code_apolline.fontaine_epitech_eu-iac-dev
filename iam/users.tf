
locals {
  iam_users = {
    "Nicolas"  = "admin"
    "Clement"  = "admin"
    "Apolline" = "admin"
    "Theo"     = "admin"
    "jeremie"  = "billing_readonly"
  }
}

resource "aws_iam_user" "users" {
  for_each = local.iam_users
  name     = each.key
  
  tags = {
    Role = each.value
    ManagedBy = "Terraform"
  }
}

resource "aws_iam_access_key" "keys" {
  for_each = aws_iam_user.users
  user     = each.value.name
}

resource "aws_iam_user_policy_attachment" "admin_attach" {
  for_each   = { for k, v in aws_iam_user.users : k => v if local.iam_users[k] == "admin" }
  user       = each.value.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_user_policy_attachment" "readonly_attach" {
  for_each   = { for k, v in aws_iam_user.users : k => v if local.iam_users[k] == "billing_readonly" }
  user       = each.value.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_user_policy_attachment" "billing_attach" {
  for_each   = { for k, v in aws_iam_user.users : k => v if local.iam_users[k] == "billing_readonly" }
  user       = each.value.name
  policy_arn = "arn:aws:iam::aws:policy/job-function/Billing"
}

# Optionnel: générer un fichier de credentials
resource "local_file" "credentials_file" {
  filename = "aws-credentials.txt"
  content  = join("\n\n", [for username, key in aws_iam_access_key.keys : "[${username}]\naws_access_key_id = ${key.id}\naws_secret_access_key = ${key.secret}"])
  
  # Permissions restreintes
  file_permission = "0600"
}

# Output pour voir les clés créées
output "user_access_keys" {
  value = {
    for username, key in aws_iam_access_key.keys : username => {
      access_key_id = key.id
      secret_access_key = key.secret
    }
  }
  sensitive = true
  description = "Access keys pour les nouveaux utilisateurs (sensible)"
}