
output "s3_irsa_role" {
  value = aws_iam_role.s3_irsa_role.arn
}

output "ebs_csi_role_arn" {
  description = "ARN of the EBS CSI IAM role"
  value       = aws_iam_role.ebs_csi_role.arn
}