variable "cluster_identifier" {
  description = "Unique identifier for the Redshift cluster"
  type        = string
  default     = "chat-analytics-cluster"
}

variable "database_name" {
  description = "Name of the default database in the cluster"
  type        = string
  default     = "analytics_db"
}

variable "master_username" {
  description = "Master username for the Redshift cluster"
  type        = string
  sensitive   = true
}

variable "master_password" {
  description = "Master password for the Redshift cluster"
  type        = string
  sensitive   = true
}

variable "node_type" {
  description = "The node type to be provisioned for the cluster (e.g., ra3.4xlarge, ra3.xlplus)"
  type        = string
  default     = "ra3.4xlarge"
  
  validation {
    condition = can(regex("^(ra3|dc2|ds2)", var.node_type))
    error_message = "Node type must be a valid Redshift node type (ra3, dc2, or ds2)."
  }
}

variable "number_of_nodes" {
  description = "Number of nodes in the cluster (1 for single-node, 2+ for multi-node)"
  type        = number
  default     = 2
  
  validation {
    condition     = var.number_of_nodes >= 1 && var.number_of_nodes <= 100
    error_message = "Number of nodes must be between 1 and 100."
  }
}

variable "vpc_id" {
  description = "VPC ID where the Redshift cluster will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the Redshift subnet group (should be in different AZs)"
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "List of security group IDs allowed to access Redshift (in addition to VPC CIDR)"
  type        = list(string)
  default     = []
}

variable "publicly_accessible" {
  description = "Whether the cluster is publicly accessible"
  type        = bool
  default     = false
}

variable "encrypted" {
  description = "Whether the cluster is encrypted"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID for encryption (if not provided, uses default AWS managed key)"
  type        = string
  default     = null
}

variable "automated_snapshot_retention_period" {
  description = "Number of days to retain automated snapshots (0-35)"
  type        = number
  default     = 7
  
  validation {
    condition     = var.automated_snapshot_retention_period >= 0 && var.automated_snapshot_retention_period <= 35
    error_message = "Automated snapshot retention period must be between 0 and 35 days."
  }
}

variable "preferred_maintenance_window" {
  description = "Weekly time range for maintenance (e.g., 'sun:04:00-sun:05:00')"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "allow_version_upgrade" {
  description = "Allow major version upgrades automatically"
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "Apply changes immediately instead of waiting for maintenance window"
  type        = bool
  default     = false
}

variable "enable_logging" {
  description = "Enable logging to CloudWatch"
  type        = bool
  default     = true
}

variable "enhanced_vpc_routing" {
  description = "Enable enhanced VPC routing (forces all COPY/UNLOAD traffic through VPC)"
  type        = bool
  default     = true
}

variable "require_ssl" {
  description = "Require SSL for connections"
  type        = bool
  default     = true
}

variable "parameter_group_family" {
  description = "Parameter group family (e.g., redshift-1.0)"
  type        = string
  default     = "redshift-1.0"
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket for data loading/unloading"
  type        = string
}

variable "msk_cluster_arn" {
  description = "ARN of the MSK cluster for streaming ingestion"
  type        = string
}

variable "skip_final_snapshot_on_destroy" {
  description = "Skip final snapshot when destroying the cluster (WARNING: data loss)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

