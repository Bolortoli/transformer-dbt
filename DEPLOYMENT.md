# dbt Deployment Guide

This guide provides comprehensive instructions for deploying the Shoppy Data Warehouse dbt project across different environments.

## 🚀 Quick Start

1. **Set up environment variables**:
   ```bash
   cp .env.example .env
   # Edit .env with your actual values
   ```

2. **Deploy to development**:
   ```bash
   ./deploy.sh dev build
   ```

3. **Deploy to production**:
   ```bash
   ./deploy.sh prod build
   ```

## 📋 Prerequisites

### Required Software
- dbt-core >= 1.5.0
- dbt-bigquery >= 1.5.0
- Google Cloud SDK (gcloud)
- Bash shell

### Required Access
- BigQuery project with appropriate permissions
- Service account key with BigQuery Data Editor and Job User roles
- Access to source data in shoppy_aurora schema

## 🔧 Environment Configuration

### Environment Variables

Set the following environment variables (see `.env.example`):

| Variable | Description | Example |
|----------|-------------|---------|
| `BIGQUERY_PROJECT_ID` | Your GCP project ID | `my-data-project` |
| `BIGQUERY_DATASET` | Target dataset name | `transformer_dbt_prod` |
| `BIGQUERY_LOCATION` | BigQuery region | `US` or `EU` |
| `GOOGLE_APPLICATION_CREDENTIALS` | Path to service account JSON | `/path/to/key.json` |
| `DBT_TARGET` | Target environment | `dev`, `staging`, `prod` |

### Service Account Setup

1. Create a service account in Google Cloud Console
2. Grant the following roles:
   - BigQuery Data Editor
   - BigQuery Job User
   - BigQuery Read Session User
3. Download the JSON key file
4. Set `GOOGLE_APPLICATION_CREDENTIALS` to the file path

## 🎯 Target Environments

### Development (`dev`)
- **Dataset**: `transformer_dbt_dev`
- **Purpose**: Local development and testing
- **Threads**: 4
- **Priority**: Interactive

### Staging (`staging`)
- **Dataset**: `transformer_dbt_staging`
- **Purpose**: Pre-production testing and validation
- **Threads**: 6
- **Priority**: Interactive
- **Cost Control**: 500MB query limit

### Production (`prod`)
- **Dataset**: `transformer_dbt_prod`
- **Purpose**: Production data warehouse
- **Threads**: 8
- **Priority**: Batch
- **Cost Control**: 1GB query limit
- **Timeouts**: Extended for large datasets

## 🛠️ Deployment Commands

### Using the Deployment Script

The `deploy.sh` script provides automated deployment with environment management:

```bash
./deploy.sh [environment] [command]
```

**Available environments**: `dev`, `staging`, `prod`
**Available commands**:

| Command | Description |
|---------|-------------|
| `run` | Execute dbt models (default) |
| `test` | Run data quality tests |
| `build` | Run models + tests |
| `compile` | Compile models without execution |
| `seed` | Load seed data |
| `docs` | Generate and serve documentation |
| `fresh` | Check source data freshness |
| `full-refresh` | Full refresh of incremental models |

### Examples

```bash
# Development deployment
./deploy.sh dev build

# Production deployment with full refresh
./deploy.sh prod full-refresh

# Run tests only
./deploy.sh staging test

# Generate documentation
./deploy.sh prod docs
```

### Manual dbt Commands

For advanced usage, you can run dbt commands directly:

```bash
# Set target environment
export DBT_TARGET=prod

# Install dependencies
dbt deps

# Test connection
dbt debug

# Run specific models
dbt run --select fct_listing

# Run models with full refresh
dbt run --full-refresh

# Run tests for specific model
dbt test --select fct_listing
```

## 📊 Model Configuration

### Fact Tables
- **Materialization**: Incremental with daily partitioning
- **Clustering**: Optimized for query performance
- **Schema Changes**: Automatically append new columns

### Dimension Tables
- **Materialization**: Full table refresh
- **SCD Support**: Type 1 and Type 2 slowly changing dimensions
- **Unique Keys**: Enforced via configuration

### Staging Models
- **Materialization**: Views for lightweight processing
- **Schema**: Separate staging namespace

## 🔍 Monitoring and Validation

### Pre-deployment Checks
1. **Connection Test**: `dbt debug`
2. **Compilation**: `dbt compile`
3. **Source Freshness**: `dbt source freshness`

### Post-deployment Validation
1. **Data Quality Tests**: `dbt test`
2. **Row Count Validation**: Check key tables
3. **Performance Monitoring**: Query execution times

### Automated Checks

The deployment script automatically:
- Validates environment parameters
- Tests BigQuery connection
- Installs required packages
- Provides detailed logging

## 🚨 Troubleshooting

### Common Issues

**Authentication Error**:
```
Error: Could not authenticate to BigQuery
```
- Verify `GOOGLE_APPLICATION_CREDENTIALS` path
- Check service account permissions

**Dataset Not Found**:
```
Error: Dataset not found: transformer_dbt_prod
```
- Create the dataset in BigQuery console
- Verify `BIGQUERY_PROJECT_ID` is correct

**Incremental Model Issues**:
```
Error: Relation does not exist
```
- Run with `--full-refresh` flag for first deployment
- Check source table availability

### Performance Issues

**Slow Query Execution**:
- Check clustering and partitioning configuration
- Verify BigQuery location matches data location
- Increase thread count for production

**Cost Management**:
- Monitor `maximum_bytes_billed` settings
- Use batch priority for production runs
- Implement query result caching

## 📚 Best Practices

### Development Workflow
1. Develop in `dev` environment
2. Test in `staging` environment
3. Deploy to `prod` with validation

### Code Quality
- Use schema tests for all models
- Document model purpose and grain
- Follow naming conventions

### Performance Optimization
- Use incremental models for large fact tables
- Implement proper partitioning and clustering
- Monitor query performance regularly

### Security
- Use service accounts, not personal credentials
- Implement least-privilege access
- Store credentials securely

## 🔄 CI/CD Integration

For automated deployments, integrate with your CI/CD pipeline:

```yaml
# Example GitHub Actions workflow
- name: Deploy dbt to production
  run: |
    export DBT_TARGET=prod
    ./deploy.sh prod build
```

## 📞 Support

For deployment issues or questions:
1. Check the troubleshooting section
2. Review dbt logs in `logs/` directory
3. Validate environment configuration
4. Contact the data engineering team

---

**Remember**: Always test in `dev` or `staging` before deploying to production! 🚨