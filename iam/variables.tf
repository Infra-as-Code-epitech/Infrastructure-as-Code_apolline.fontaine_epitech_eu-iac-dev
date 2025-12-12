variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "prof_account" {
    description = "The AWS profile for the target account"
    type = string
    default = "Jeremie"
}

variable "filename" {
    description = "The name of the file that holds IAM user credentials"
    type = string
    default = "developer_access_account_info.txt"
}