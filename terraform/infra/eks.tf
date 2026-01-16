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

resource "aws_iam_role_policy_attachment" "rds_connect_attachment" {
  role       = aws_iam_role.eks_pod_identity_app.name
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
  role       = aws_iam_role.eks_pod_identity_app.name
  policy_arn = aws_iam_policy.read_config.arn
}

resource "aws_iam_role" "eks_pod_identity_app" {
  name               = "eks-pod-identity-app"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_eks_access_entry" "app" {
  cluster_name  = module.eks-managed-node-group.cluster_name
  principal_arn = aws_iam_role.eks_pod_identity_app.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "app_cluster_admin" {
  cluster_name  = module.eks-managed-node-group.cluster_name
  principal_arn = aws_iam_role.eks_pod_identity_app.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.app]
}

resource "aws_eks_pod_identity_association" "pod_identity_association_app" {
  cluster_name    = module.eks-managed-node-group.cluster_name
  namespace       = "app"
  service_account = "app-sa"
  role_arn        = aws_iam_role.eks_pod_identity_app.arn
}

# ------------------------------------------------------------------

resource "aws_prometheus_workspace" "main" {
  alias = "eks-observability"
}

resource "aws_iam_policy" "adot_collector" {
  name = "adot-collector-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "aps:RemoteWrite", "aps:GetSeries", "aps:GetLabels", "aps:GetMetricMetadata",
          "xray:PutTraceSegments", "xray:PutTelemetryRecords", "xray:GetSamplingRules",
          "logs:PutLogEvents", "logs:CreateLogGroup", "logs:CreateLogStream", "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "adot_collector_attachment" {
  role       = aws_iam_role.eks_pod_identity_observability.name
  policy_arn = aws_iam_policy.adot_collector.arn
}

resource "aws_iam_role" "eks_pod_identity_observability" {
  name               = "eks-pod-identity-observability"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_eks_pod_identity_association" "pod_identity_association_observability" {
  cluster_name    = module.eks-managed-node-group.cluster_name
  namespace       = "observability"
  service_account = "observability-sa"
  role_arn        = aws_iam_role.eks_pod_identity_observability.arn
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

  compute_config = {
    enabled    = true
    node_pools = ["general-purpose", "system"]
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
    metrics-server = {
      configuration_values = jsonencode({
        args = [
          "--kubelet-insecure-tls",
          "--kubelet-preferred-address-types=InternalIP"
        ]
      })
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
