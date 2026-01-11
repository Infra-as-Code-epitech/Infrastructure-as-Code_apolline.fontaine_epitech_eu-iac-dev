data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}

resource "aws_iam_policy" "rds_connect" {
  name        = "rds-connect-policy"
  description = "Allow connection to RDS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["rds-db:connect"]
        Effect   = "Allow"
        Resource = aws_db_instance.rds.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_pod_identity_attachment" {
  role       = aws_iam_role.eks_pod_identity.name
  policy_arn = aws_iam_policy.rds_connect.arn
}

resource "aws_iam_policy" "read_config" {
  name = "task-manager-read-config"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "secretsmanager:GetSecretValue"
      Resource = [
        aws_secretsmanager_secret.app_config.arn,
        aws_db_instance.rds.master_user_secret[0].secret_arn
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "read_config_attachment" {
  role       = aws_iam_role.eks_pod_identity.name
  policy_arn = aws_iam_policy.read_config.arn
}

resource "aws_iam_role" "eks_pod_identity" {
  name               = "eks-pod-identity-example"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_eks_pod_identity_association" "example" {
  cluster_name    = module.eks-managed-node-group.cluster_name
  namespace       = "app"
  service_account = "app-sa"
  role_arn        = aws_iam_role.eks_pod_identity.arn
}

module "eks-managed-node-group" {
  source             = "terraform-aws-modules/eks/aws"
  version            = "~> 21.0"
  kubernetes_version = "1.33"
  create             = true
  name               = var.eks_name
  region             = var.region
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnets

  eks_managed_node_groups = {
    app_node_group = {
      instance_types = ["t3.small"]
      ami_type       = "AL2023_x86_64_STANDARD"
      min_size       = 1
      max_size       = 5
      desired_size   = 1
      subnet_ids     = module.vpc.private_subnets
      timeouts = {
        create = "15m"
        update = "15m"
        delete = "20m"
      }
      iam_role_additional_policies = {
        AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
      }
    },
    runners_node_group = {
      instance_types = ["t3.small"]
      ami_type       = "AL2023_x86_64_STANDARD"
      min_size       = 1
      max_size       = 5
      desired_size   = 1
      subnet_ids     = module.vpc.private_subnets
      iam_role_additional_policies = {
        AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
      }
    }
  }
  addons = {
    coredns = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
  }

  enable_cluster_creator_admin_permissions = true
  endpoint_private_access                  = true
  endpoint_public_access                   = true
  timeouts = {
    create = "15m"
    update = "15m"
    delete = "20m"
  }
  tags = var.tags
}
