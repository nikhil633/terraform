resource "aws_eks_access_entry" "jenkins" {
  cluster_name  = var.aws_eks_cluster
  principal_arn = var.jenkins
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "jenkins" {
  cluster_name  = var.aws_eks_cluster
  principal_arn = var.jenkins

  policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [
    aws_eks_access_entry.jenkins
  ]
  
}