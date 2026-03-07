# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-03-07

### Added

- Aurora cluster resource with MySQL and PostgreSQL engine support
- Cluster instances with configurable promotion tiers
- DB subnet group for network isolation
- Cluster and instance parameter groups with custom parameters
- Global database support for cross-region replication
- RDS Proxy with TLS enforcement, IAM authentication, and read-only endpoint
- Database Activity Streams with Kinesis integration
- Application Auto Scaling for read replicas (target tracking on CPU)
- Security group with least-privilege ingress rules
- Enhanced monitoring with dedicated IAM role
- CloudWatch alarms for CPU utilization, database connections, and replication lag
- Performance Insights support with configurable retention
- Secrets Manager integration for master password management
- IAM database authentication
- KMS encryption at rest with customer-managed key support
- Serverless scaling configuration support
- Basic, advanced, and complete usage examples
- Comprehensive documentation with architecture diagrams

[1.0.0]: https://github.com/kogunlowo123/terraform-aws-rds-aurora/releases/tag/v1.0.0
