# Redshift Cluster Terraform Module

This Terraform module provisions an Amazon Redshift cluster optimized for high-throughput data ingestion from MSK (Kafka) and S3, based on the chat analytics schema requirements.

## Features

- **Production-ready configuration** with RA3 node types for high throughput
- **IAM roles** for S3 and MSK access (required for streaming ingestion)
- **Security groups** with VPC integration
- **Parameter groups** with performance optimizations
- **Encryption** support (KMS)
- **CloudWatch logging** enabled
- **Automated snapshots** for backup
- **Enhanced VPC routing** for optimal network performance

## Architecture

The module creates:
1. Redshift cluster with configurable node type and count
2. IAM roles for S3 and MSK access
3. Security group for network access control
4. Subnet group for VPC deployment
5. Parameter group with performance optimizations

## Usage

### Basic Example

```hcl
module "redshift_cluster" {
  source = "./terraform/redshift"

  cluster_identifier = "chat-analytics-cluster"
  database_name      = "analytics_db"
  master_username    = "admin"
  master_password    = var.redshift_password  # Use secrets manager

  node_type       = "ra3.4xlarge"
  number_of_nodes = 2

  vpc_id    = "vpc-xxxxxxxxxxxxx"
  subnet_ids = [
    "subnet-xxxxxxxxxxxxx",
    "subnet-yyyyyyyyyyyyy"
  ]

  s3_bucket_arn  = "arn:aws:s3:::chat-messages-data-lake"
  msk_cluster_arn = "arn:aws:kafka:us-east-1:123456789012:cluster/chat-cluster/xxxxx"

  tags = {
    Environment = "production"
    Project     = "chat-analytics"
  }
}
```

### High-Throughput Configuration (1M+ events/sec)

For handling millions of events per second, use:

```hcl
module "redshift_cluster" {
  source = "./terraform/redshift"

  cluster_identifier = "chat-analytics-cluster"
  node_type          = "ra3.4xlarge"
  number_of_nodes    = 20  # Scale based on throughput requirements
  
  # ... other configuration
}
```

**Calculation for node count:**
- Average record size: 2KB
- Throughput: 1M records/sec = 2GB/sec = 2000 MB/sec
- RA3.4xlarge handles ~150 MB/sec per node
- Required nodes: 2000 / 150 ≈ 14 nodes (use 20+ for headroom)

## Setup Instructions

1. **Copy the example variables file:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit `terraform.tfvars` with your values:**
   - VPC and subnet IDs
   - Master username and password (use AWS Secrets Manager in production)
   - S3 bucket ARN
   - MSK cluster ARN
   - Node configuration

3. **Initialize Terraform:**
   ```bash
   terraform init
   ```

4. **Plan the deployment:**
   ```bash
   terraform plan
   ```

5. **Apply the configuration:**
   ```bash
   terraform apply
   ```

## Post-Deployment Setup

After the cluster is created, you'll need to:

1. **Create the external schema for MSK:**
   ```sql
   CREATE EXTERNAL SCHEMA msk_schema
   FROM MSK
   IAM_ROLE 'arn:aws:iam::account:role/chat-analytics-cluster-msk-role'
   AUTHENTICATION 'sasl_ssl_scram_sha_512'
   PROPERTIES (
     'msk.broker' = 'b-1.cluster.region.amazonaws.com:9096',
     'msk.topic' = 'chat-messages'
   );
   ```

2. **Create the base tables** (use `01_base_tables.sql`):
   ```bash
   psql -h <cluster-endpoint> -U admin -d analytics_db -f 01_base_tables.sql
   ```

3. **Create streaming materialized views** (if using real-time ingestion):
   ```sql
   CREATE MATERIALIZED VIEW staging_chat_messages_streaming
   AUTO REFRESH YES
   AS
   SELECT 
     JSON_PARSE(message) AS json_data,
     GETDATE() AS ingest_timestamp
   FROM msk_schema.chat_messages;
   ```

## Variables

See `variables.tf` for all available variables. Key variables:

- `cluster_identifier`: Unique cluster name
- `node_type`: Node type (ra3.4xlarge recommended)
- `number_of_nodes`: Number of nodes (2+ for multi-node)
- `vpc_id`: VPC ID for deployment
- `subnet_ids`: List of subnet IDs (should be in different AZs)
- `s3_bucket_arn`: S3 bucket ARN for data loading
- `msk_cluster_arn`: MSK cluster ARN for streaming ingestion

## Outputs

The module outputs:
- `cluster_endpoint`: Cluster endpoint hostname
- `cluster_port`: Cluster port (5439)
- `cluster_connection_string`: JDBC connection string
- `iam_role_s3_arn`: IAM role ARN for S3 access
- `iam_role_msk_arn`: IAM role ARN for MSK access
- `security_group_id`: Security group ID

## Security Best Practices

1. **Use AWS Secrets Manager** for master password (don't hardcode)
2. **Enable encryption** (`encrypted = true`)
3. **Use KMS keys** for encryption in production
4. **Require SSL** (`require_ssl = true`)
5. **Deploy in private subnets** (`publicly_accessible = false`)
6. **Use security groups** to restrict access
7. **Enable CloudWatch logging** for audit trails

## Cost Optimization

1. **Right-size the cluster**: Start with 2 nodes, scale based on actual workload
2. **Use RA3 nodes**: Better cost/performance ratio with managed storage
3. **Enable automated snapshots**: But set retention period based on needs
4. **Use S3 for cold data**: Query via Redshift Spectrum instead of storing in cluster
5. **Monitor query performance**: Use query insights to optimize

## Monitoring

Key CloudWatch metrics to monitor:
- `CPUUtilization`: Should be < 80%
- `DatabaseConnections`: Track connection usage
- `HealthStatus`: Should be "healthy"
- `QueryDuration`: Track query performance
- `StreamingIngestionRecords`: Track ingestion rate (if using streaming)

## Troubleshooting

**Cluster not accessible:**
- Check security group rules
- Verify subnet routing
- Check VPC endpoints (if using enhanced VPC routing)

**Slow queries:**
- Check SORTKEY usage in queries
- Run VACUUM and ANALYZE regularly
- Consider scaling up nodes

**High costs:**
- Review node count and type
- Check for unused snapshots
- Optimize query patterns

## References

- [Redshift Documentation](https://docs.aws.amazon.com/redshift/)
- [Redshift Streaming Ingestion](https://docs.aws.amazon.com/redshift/latest/dg/materialized-view-streaming-ingestion.html)
- [MSK to Redshift Setup](https://docs.aws.amazon.com/redshift/latest/dg/materialized-view-streaming-ingestion-getting-started-MSK.html)

