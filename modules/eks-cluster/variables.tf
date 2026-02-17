# ------------------------------------------------------------------------------
# EKS Cluster Module Variables
# ------------------------------------------------------------------------------

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.29"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for worker nodes"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for EKS API endpoint"
  type        = list(string)
}

variable "endpoint_private_access" {
  description = "Enable private API endpoint"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public API endpoint"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "CIDR blocks that can access the public API endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "service_ipv4_cidr" {
  description = "CIDR block for Kubernetes service IPs"
  type        = string
  default     = "172.20.0.0/16"
}

variable "kms_key_arn" {
  description = "KMS key ARN for secrets encryption"
  type        = string
  default     = null
}

variable "cluster_log_types" {
  description = "EKS control plane logging types"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "node_groups" {
  description = "Map of managed node group configurations"
  type = map(object({
    instance_types             = list(string)
    desired_size               = number
    max_size                   = number
    min_size                   = number
    capacity_type              = optional(string, "ON_DEMAND")
    disk_size                  = optional(number, 50)
    ami_type                   = optional(string, "AL2_x86_64")
    max_unavailable_percentage = optional(number, 33)
    labels                     = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = optional(string)
      effect = string
    })), [])
  }))
}

# Add-on Versions
variable "vpc_cni_version" {
  description = "VPC CNI add-on version"
  type        = string
  default     = null
}

variable "coredns_version" {
  description = "CoreDNS add-on version"
  type        = string
  default     = null
}

variable "kube_proxy_version" {
  description = "kube-proxy add-on version"
  type        = string
  default     = null
}

variable "ebs_csi_version" {
  description = "EBS CSI driver add-on version"
  type        = string
  default     = null
}

variable "enable_ebs_csi_driver" {
  description = "Enable EBS CSI driver add-on"
  type        = bool
  default     = true
}

variable "enable_prefix_delegation" {
  description = "Enable VPC CNI prefix delegation for higher pod density"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
