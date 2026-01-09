
resource "aws_eks_addon" "adot" {
  cluster_name = eks-dev
  addon_name   = "adot"
  addon_version = "v0.88.0-eksbuild.1" 
  
  configuration_values = jsonencode({
    manager = {
      serviceAccount = {
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.adot_collector.arn
        }
      }
    }
  })
}
