# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_vpc" "main" {
  id = var.vpc_id
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  
  filter {
    name   = "tag:Type"
    values = ["private"]
  }
}

# IAM Role for Redshift to access S3
resource "aws_iam_role" "redshift_s3_role" {
  name = "${var.cluster_identifier}-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "redshift.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "redshift_s3_policy" {
  name = "${var.cluster_identifier}-s3-policy"
  role = aws_iam_role.redshift_s3_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "${var.s3_bucket_arn}/*",
          var.s3_bucket_arn
        ]
      }
    ]
  })
}

# IAM Role for Redshift to access MSK
resource "aws_iam_role" "redshift_msk_role" {
  name = "${var.cluster_identifier}-msk-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "redshift.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "redshift_msk_policy" {
  name = "${var.cluster_identifier}-msk-policy"
  role = aws_iam_role.redshift_msk_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kafka:DescribeCluster",
          "kafka:GetBootstrapBrokers",
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:ReadData",
          "kafka-cluster:DescribeGroup"
        ]
        Resource = [
          "${var.msk_cluster_arn}/*"
        ]
      }
    ]
  })
}

# Security Group for Redshift
resource "aws_security_group" "redshift" {
  name        = "${var.cluster_identifier}-sg"
  description = "Security group for Redshift cluster ${var.cluster_identifier}"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Redshift port from VPC"
    from_port       = 5439
    to_port         = 5439
    protocol        = "tcp"
    cidr_blocks     = [data.aws_vpc.main.cidr_block]
    security_groups = var.allowed_security_group_ids
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_identifier}-sg"
    }
  )
}

# Redshift Subnet Group
resource "aws_redshift_subnet_group" "main" {
  name       = "${var.cluster_identifier}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_identifier}-subnet-group"
    }
  )
}

# Redshift Parameter Group
resource "aws_redshift_parameter_group" "main" {
  name        = "${var.cluster_identifier}-parameter-group"
  family      = var.parameter_group_family
  description = "Parameter group for ${var.cluster_identifier}"

  # Performance optimizations
  parameter {
    name  = "enable_user_activity_logging"
    value = "true"
  }

  parameter {
    name  = "max_query_result_size"
    value = "100000"
  }

  parameter {
    name  = "query_group"
    value = "default"
  }

  parameter {
    name  = "require_ssl"
    value = var.require_ssl ? "true" : "false"
  }

  tags = var.tags
}

# Redshift Cluster
resource "aws_redshift_cluster" "main" {
  cluster_identifier        = var.cluster_identifier
  database_name             = var.database_name
  master_username           = var.master_username
  master_password           = var.master_password
  node_type                 = var.node_type
  number_of_nodes           = var.number_of_nodes
  cluster_type              = var.number_of_nodes > 1 ? "multi-node" : "single-node"
  
  # Network configuration
  vpc_security_group_ids    = [aws_security_group.redshift.id]
  cluster_subnet_group_name = aws_redshift_subnet_group.main.name
  publicly_accessible       = var.publicly_accessible
  port                      = 5439
  
  # IAM roles
  iam_roles = [
    aws_iam_role.redshift_s3_role.arn,
    aws_iam_role.redshift_msk_role.arn
  ]
  
  # Parameter group
  parameter_group_name = aws_redshift_parameter_group.main.name
  
  # Encryption
  encrypted                 = var.encrypted
  kms_key_id                = var.kms_key_id
  
  # Backup and maintenance
  automated_snapshot_retention_period = var.automated_snapshot_retention_period
  preferred_maintenance_window        = var.preferred_maintenance_window
  allow_version_upgrade               = var.allow_version_upgrade
  apply_immediately                   = var.apply_immediately
  
  # Logging
  dynamic "logging" {
    for_each = var.enable_logging ? [1] : []
    content {
      enable              = true
      log_destination_type = "cloudwatch"
      log_exports          = ["connectionlog", "userlog", "useractivitylog"]
    }
  }
  
  # Performance and features
  enhanced_vpc_routing = var.enhanced_vpc_routing
  
  # Tags
  tags = merge(
    var.tags,
    {
      Name = var.cluster_identifier
    }
  )

  # Skip final snapshot on destroy (set to false for production)
  skip_final_snapshot = var.skip_final_snapshot_on_destroy
  
  # Final snapshot identifier (if skip_final_snapshot is false)
  final_snapshot_identifier = var.skip_final_snapshot_on_destroy ? null : "${var.cluster_identifier}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  depends_on = [
    aws_iam_role_policy.redshift_s3_policy,
    aws_iam_role_policy.redshift_msk_policy
  ]
}

