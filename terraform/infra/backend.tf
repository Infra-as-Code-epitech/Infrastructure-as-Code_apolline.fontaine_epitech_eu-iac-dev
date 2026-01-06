terraform {
  backend "s3" {
    bucket = ""
    key    = "infra/terraform.tfstate"
    region = ""
  }
}
