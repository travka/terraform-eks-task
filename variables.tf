variable "region" {
  description = "AWS region for the resources."
  type        = string
  default     = "us-west-2"
}

variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
  default     = "my-eks-cluster"
}

variable "cluster_version" {
  description = "Version of the EKS cluster."
  type        = string
  default     = "1.27"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "tags" {
  description = "Tags to apply to resources."
  type        = map(string)
  default     = {
    Terraform = "true"
  }
}

variable "bucket_name" {
  description = "Name of the S3 bucket."
  type        = string
  default     = "my-eks-bucket"
}

variable "instance_type" {
  description = "Instance type for the EKS managed node group."
  type        = string
  default     = "t3.medium"
}
