# Basic Aurora PostgreSQL Example

This example deploys a simple Aurora PostgreSQL cluster with two instances and default settings.

## Features

- Aurora PostgreSQL 15.4
- Two instances (writer + one reader)
- Secrets Manager managed password
- Performance Insights enabled
- Enhanced monitoring enabled

## Usage

```bash
terraform init
terraform plan
terraform apply
```

## Inputs

| Name | Description | Default |
|------|-------------|---------|
| None | All values are hardcoded for simplicity | - |

## Outputs

| Name | Description |
|------|-------------|
| cluster_endpoint | The writer endpoint |
| reader_endpoint | The reader endpoint |
