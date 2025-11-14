output "cluster_identifier" {
  description = "Redshift cluster identifier"
  value       = aws_redshift_cluster.main.cluster_identifier
}

output "cluster_endpoint" {
  description = "Redshift cluster endpoint (hostname)"
  value       = aws_redshift_cluster.main.endpoint
}

output "cluster_port" {
  description = "Redshift cluster port"
  value       = aws_redshift_cluster.main.port
}

output "cluster_database_name" {
  description = "Name of the default database"
  value       = aws_redshift_cluster.main.database_name
}

output "cluster_master_username" {
  description = "Master username for the cluster"
  value       = aws_redshift_cluster.main.master_username
  sensitive   = true
}

output "cluster_connection_string" {
  description = "JDBC connection string for the cluster"
  value       = "jdbc:redshift://${aws_redshift_cluster.main.endpoint}:${aws_redshift_cluster.main.port}/${aws_redshift_cluster.main.database_name}"
}

output "cluster_psql_connection_string" {
  description = "PostgreSQL connection string for the cluster"
  value       = "postgresql://${aws_redshift_cluster.main.master_username}:<password>@${aws_redshift_cluster.main.endpoint}:${aws_redshift_cluster.main.port}/${aws_redshift_cluster.main.database_name}"
}

output "iam_role_s3_arn" {
  description = "ARN of the IAM role for S3 access"
  value       = aws_iam_role.redshift_s3_role.arn
}

output "iam_role_msk_arn" {
  description = "ARN of the IAM role for MSK access"
  value       = aws_iam_role.redshift_msk_role.arn
}

output "security_group_id" {
  description = "Security group ID for the Redshift cluster"
  value       = aws_security_group.redshift.id
}

output "subnet_group_name" {
  description = "Name of the Redshift subnet group"
  value       = aws_redshift_subnet_group.main.name
}

output "parameter_group_name" {
  description = "Name of the Redshift parameter group"
  value       = aws_redshift_parameter_group.main.name
}

