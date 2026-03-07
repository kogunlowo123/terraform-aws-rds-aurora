# Complete Enterprise Aurora Deployment

This example deploys a full enterprise-grade Aurora PostgreSQL cluster with global database, RDS Proxy, activity streams, and comprehensive monitoring.

## Features

- Aurora PostgreSQL 15.4 with global database (cross-region)
- Three instances with auto-scaling (2-10 replicas)
- RDS Proxy with TLS and read-only endpoint
- Database Activity Streams (async mode)
- Customer-managed KMS encryption with key rotation
- Enhanced monitoring at 15-second intervals
- Performance Insights with 31-day retention
- CloudWatch log exports
- Custom cluster and instance parameter groups
- IAM database authentication
- 35-day backup retention
- Deletion protection and final snapshots

## Architecture

```
                        Global Database
                    /                     \
    us-east-1 (Primary)            eu-west-1 (Secondary)
         |                              |
    RDS Proxy (TLS)                Aurora Cluster
         |                         (read replicas)
    Aurora Cluster
    |-- Writer (r6g.2xlarge)
    |-- Reader 1
    |-- Reader 2
    |-- (auto-scaled: up to 10)
         |
    Activity Stream --> Kinesis --> Analysis
```

## Security

- Encryption at rest with customer-managed KMS key
- Encryption in transit via TLS (enforced by RDS Proxy)
- IAM database authentication
- Secrets Manager managed credentials
- Activity Streams for audit compliance (SOC2)
- Security group with least-privilege access

## Usage

```bash
terraform init
terraform plan
terraform apply
```

## Estimated Cost

- db.r6g.2xlarge instances (3x): ~$2,400/month
- RDS Proxy: ~$150/month
- Activity Streams: ~$50/month
- Performance Insights (31-day): ~$25/instance/month
- Enhanced Monitoring: included
- Global database cross-region replication: ~$200/month

**Estimated total: ~$3,000/month** (varies by region and usage)

## Outputs

| Name | Description |
|------|-------------|
| cluster_endpoint | Primary cluster writer endpoint |
| reader_endpoint | Primary cluster reader endpoint |
| proxy_endpoint | RDS Proxy endpoint |
| proxy_read_only_endpoint | RDS Proxy read-only endpoint |
| global_cluster_id | Global cluster identifier |
| activity_stream_kinesis | Kinesis stream for database activity |
| security_group_id | Security group ID |
