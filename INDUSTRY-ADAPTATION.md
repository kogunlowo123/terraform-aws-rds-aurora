# Industry Adaptation Guide

## Overview
The `terraform-aws-rds-aurora` module deploys Amazon Aurora (MySQL or PostgreSQL) clusters with configurable encryption, automated backups, performance insights, enhanced monitoring, RDS Proxy, activity streams, auto-scaling read replicas, global clusters, and custom parameter groups. Its comprehensive data protection and observability features make it suitable for any industry handling sensitive or high-throughput data.

## Healthcare
### Compliance Requirements
- HIPAA, HITRUST, HL7 FHIR
### Configuration Changes
- Set `storage_encrypted = true` with a customer-managed `kms_key_arn` for HIPAA encryption at rest.
- Set `manage_master_user_password = true` to store credentials in AWS Secrets Manager with automatic rotation.
- Set `backup_retention_period = 35` (maximum) for PHI data retention and recovery requirements.
- Set `enable_deletion_protection = true` and `skip_final_snapshot = false` to prevent accidental data loss.
- Set `iam_database_authentication_enabled = true` to replace password-based authentication with IAM roles.
- Enable `enable_activity_stream = true` with `activity_stream_mode = "sync"` for tamper-proof database audit logs (HIPAA Audit Controls).
- Configure `enabled_cloudwatch_logs_exports` with `["audit", "error"]` for MySQL or `["postgresql"]` for PostgreSQL.
- Set `enable_enhanced_monitoring = true` with `monitoring_interval = 1` for granular performance tracking.
### Example Use Case
A healthcare SaaS company stores FHIR patient records in an Aurora PostgreSQL cluster with KMS encryption, synchronous activity streams for audit compliance, IAM authentication for application access, and 35-day backup retention for disaster recovery.

## Finance
### Compliance Requirements
- SOX, PCI-DSS, SOC 2
### Configuration Changes
- Set `storage_encrypted = true` with a customer-managed `kms_key_arn` (PCI-DSS Requirement 3.4).
- Enable `enable_activity_stream = true` with `activity_stream_mode = "sync"` for real-time, tamper-proof audit logs (SOX Section 802).
- Set `backup_retention_period = 35` and `skip_final_snapshot = false` for data retention compliance.
- Configure `instance_count = 3` or higher with `autoscaling_enabled = true` for high availability of transaction processing.
- Enable `enable_rds_proxy = true` with `proxy_require_tls = true` to enforce TLS connections and connection pooling (PCI-DSS Requirement 4.1).
- Set `enable_performance_insights = true` with `performance_insights_retention_period = 731` for long-term query analysis.
- Use `cluster_parameter_group_parameters` to enforce `require_secure_transport = 1` (MySQL) or `ssl = on` (PostgreSQL).
### Example Use Case
A payments processor runs its transaction database on a 5-node Aurora MySQL cluster with RDS Proxy enforcing TLS, synchronous activity streams feeding a SIEM, auto-scaling read replicas for reporting, and encrypted storage with a dedicated KMS key.

## Government
### Compliance Requirements
- FedRAMP, CMMC, NIST 800-53
### Configuration Changes
- Deploy with `storage_encrypted = true` using a FIPS-validated `kms_key_arn` (NIST SC-28).
- Set `iam_database_authentication_enabled = true` for strong authentication (NIST IA-2).
- Enable `enable_activity_stream = true` for continuous monitoring of database operations (NIST AU-2, AU-12).
- Set `backup_retention_period = 35` and `enable_deletion_protection = true` (NIST CP-9, CP-10).
- Enable `enable_global_cluster = true` for cross-region disaster recovery of critical government data (NIST CP-6).
- Set `enabled_cloudwatch_logs_exports` to export all available log types.
- Configure `enable_enhanced_monitoring = true` with `monitoring_interval = 1` (NIST SI-4).
### Example Use Case
A federal agency deploys an Aurora PostgreSQL global cluster across two GovCloud regions for its case management system, with FIPS KMS encryption, activity streams, IAM authentication, and enhanced monitoring at 1-second intervals.

## Retail / E-Commerce
### Compliance Requirements
- PCI-DSS, CCPA/GDPR
### Configuration Changes
- Set `storage_encrypted = true` for customer payment and PII data at rest.
- Enable `enable_rds_proxy = true` with `proxy_require_tls = true` for connection pooling during traffic spikes.
- Configure `autoscaling_enabled = true` with `autoscaling_max_capacity = 10` and `autoscaling_target_cpu = 70` to handle peak shopping periods.
- Use `engine_mode = "provisioned"` with `scaling_configuration` for Aurora Serverless v2 on variable-demand workloads.
- Set `backup_retention_period = 14` for operational recovery and `skip_final_snapshot = false`.
- Enable `enable_performance_insights = true` to identify slow product catalog queries.
- Use `allowed_cidr_blocks` and `allowed_security_group_ids` to restrict database access to application subnets only.
### Example Use Case
An e-commerce platform uses Aurora MySQL with RDS Proxy to handle 10x traffic spikes during flash sales, auto-scaling read replicas serve product search queries, while the writer instance handles order processing with encrypted storage.

## Education
### Compliance Requirements
- FERPA, COPPA
### Configuration Changes
- Set `storage_encrypted = true` to protect student education records at rest.
- Set `manage_master_user_password = true` for Secrets Manager-managed credentials.
- Set `iam_database_authentication_enabled = true` for application-level access without embedded passwords.
- Set `backup_retention_period = 35` and `enable_deletion_protection = true` for data protection.
- Configure `enabled_cloudwatch_logs_exports` for audit logging of queries accessing student records.
- Use `allowed_security_group_ids` to restrict access to only the student information system application tier.
### Example Use Case
A school district stores student records in an Aurora PostgreSQL cluster with encryption, IAM authentication for the SIS application, 35-day backups, and CloudWatch audit logs exported for FERPA compliance reviews.

## SaaS / Multi-Tenant
### Compliance Requirements
- SOC 2, ISO 27001
### Configuration Changes
- Use `engine_mode = "provisioned"` with `autoscaling_enabled = true` to scale read replicas based on tenant load.
- Configure `instance_count = 3` or higher for production HA across availability zones.
- Enable `enable_rds_proxy = true` to manage connection pooling across hundreds of tenant connections, with `proxy_idle_client_timeout = 1800`.
- Set `enable_performance_insights = true` with `performance_insights_retention_period = 31` to track per-tenant query performance.
- Enable `enable_activity_stream = true` with `activity_stream_mode = "async"` for SOC 2 audit evidence without impacting write latency.
- Use `cluster_parameter_group_parameters` to tune connection limits, query timeouts, and shared buffers for multi-tenant workloads.
- Enable `enable_global_cluster = true` for cross-region DR if tenant SLAs require it.
### Example Use Case
A multi-tenant SaaS platform serves 500 tenants from a shared Aurora PostgreSQL cluster with RDS Proxy pooling connections, auto-scaling read replicas for reporting dashboards, async activity streams for SOC 2 audits, and a global cluster for cross-region failover.

## Cross-Industry Best Practices
- Use environment-based configuration by parameterizing `cluster_identifier`, `instance_class`, `instance_count`, and `tags` per environment.
- Always enable encryption at rest (`storage_encrypted = true`) and in transit (`proxy_require_tls = true`, SSL parameter group settings).
- Enable audit logging via `enable_activity_stream` and `enabled_cloudwatch_logs_exports`.
- Enforce least-privilege access with `iam_database_authentication_enabled = true` and restricted `allowed_security_group_ids` / `allowed_cidr_blocks`.
- Implement network segmentation by deploying into dedicated database subnets via `subnet_ids`.
- Configure backup and disaster recovery with appropriate `backup_retention_period`, `skip_final_snapshot = false`, and optionally `enable_global_cluster = true`.
