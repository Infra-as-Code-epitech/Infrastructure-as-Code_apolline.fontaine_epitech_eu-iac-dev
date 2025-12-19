locals {
  admin_users = [
    "arn:aws:iam::075006646450:user/Apolline",
    "arn:aws:iam::075006646450:user/Theo",
    "arn:aws:iam::075006646450:user/Clement",
    "arn:aws:iam::075006646450:user/jeremie",
    "arn:aws:iam::075006646450:user/Nicolas",
    "arn:aws:iam::075006646450:user/terraform"
  ]
}

resource "aws_eks_access_entry" "admins" {
  for_each = toset(local.admin_users)

  cluster_name  = module.eks-managed-node-group.cluster_name
  principal_arn = each.value
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "admin_policy" {
  for_each = toset(local.admin_users)

  cluster_name  = module.eks-managed-node-group.cluster_name
  principal_arn = each.value

  policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
  depends_on = [aws_eks_access_entry.admins]
}
