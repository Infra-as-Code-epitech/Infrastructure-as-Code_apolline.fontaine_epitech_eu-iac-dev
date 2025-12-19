module "eks-managed-node-group" {
  source             = "terraform-aws-modules/eks/aws"
  version            = "~> 21.0"
  kubernetes_version = "1.33"
  create             = true
  name               = var.eks_name
  region             = var.region
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnets
  # Maybe add names to nodes
  eks_managed_node_groups = {
    app_node_group = {
      instance_types = ["c7i-flex.large"]
      ami_type       = "AL2023_x86_64_STANDARD"
      min_size       = 1
      max_size       = 3
      desired_size   = 2
      subnet_ids     = module.vpc.private_subnets
      timeouts = {
        create = "15m"
        update = "15m"
        delete = "20m"
      }
    },
    runners_node_group = {
      instance_types = ["t3.small"]
      ami_type       = "AL2023_x86_64_STANDARD"
      min_size       = 1
      max_size       = 3
      desired_size   = 2
      subnet_ids     = module.vpc.private_subnets
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
