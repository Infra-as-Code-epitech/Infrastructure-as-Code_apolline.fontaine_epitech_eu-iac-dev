data "aws_iam_policy_document" "oidc_assume_role_policy" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:deadpanda-c/Infrastructure-as-Code_apolline.fontaine_epitech_eu-iac-dev:ref:refs/heads/main"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:deadpanda-c/Infrastructure-as-Code_apolline.fontaine_epitech_eu-iac-dev:ref:refs/heads/dev"]
    }
  }
}

resource "aws_iam_role" "oidc-role" {
  name               = var.oidc_role_name
  assume_role_policy = data.aws_iam_policy_document.oidc_assume_role_policy.json
  tags               = var.tags
}

data "aws_iam_policy_document" "terraform-policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = ["arn:aws:s3:::terraform-infraascode-bucket"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]
    resources = "arn:aws:s3:::terraform-infraascode-bucket/state/terraform.tfstate"
  }
}

resource "aws_iam_policy" "terraform-policy" {
  name        = "terraform-policy"
  description = "Allow OIDC provider to access S3 bucket for Terraform usage policy"
  policy      = data.aws_iam_policy_document.terraform-policy.json
}

resource "aws_iam_policy_attachment" "terraform-attachment" {
  name       = "terraform-attachment"
  roles      = [aws_iam_role.oidc-role.arn]
  policy_arn = aws_iam_policy.terraform-policy.arn
}

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]
}
