variable "primary_region" {
  description = "Region where the existing EKS cluster runs."
  type        = string
  default     = "ap-south-1"
}

variable "destination_region" {
  description = "Different AWS region for disaster-recovery copies."
  type        = string
  default     = "ap-southeast-1"
}

variable "eks_cluster_arn" {
  description = "ARN of the existing EKS cluster to protect."
  type        = string
}

variable "name_prefix" {
  description = "Prefix for backup resources."
  type        = string
  default     = "eks"
}
