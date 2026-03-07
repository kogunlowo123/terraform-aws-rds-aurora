# Advanced Aurora MySQL with RDS Proxy

This example deploys an Aurora MySQL cluster with RDS Proxy, auto-scaling, and enhanced monitoring.

## Features

- Aurora MySQL 8.0
- Three instances with auto-scaling (2-8 replicas)
- RDS Proxy with TLS enforcement and read-only endpoint
- Enhanced monitoring at 30-second intervals
- Performance Insights enabled
- CloudWatch log exports (audit, error, slowquery)
- Custom parameter group with UTF-8 support
- IAM database authentication
- Deletion protection enabled

## Architecture

```
Application --> RDS Proxy (TLS) --> Aurora Cluster
                  |                    |-- Writer Instance
                  |                    |-- Reader Instance 1
                  |                    |-- Reader Instance 2
                  |                    |-- (auto-scaled readers)
                  |
                  +--> Read-Only Endpoint
```

## Usage

```bash
terraform init
terraform plan
terraform apply
```

## Outputs

| Name | Description |
|------|-------------|
| cluster_endpoint | The writer endpoint |
| proxy_endpoint | The RDS Proxy endpoint |
| proxy_read_only_endpoint | The RDS Proxy read-only endpoint |
