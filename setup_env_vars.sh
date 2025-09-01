#!/bin/bash

# Required Environment Variables for DBT BigQuery Connection
# Set these environment variables before running DBT commands

echo "Setting up required environment variables for DBT BigQuery connection..."
echo ""
echo "Required environment variables:"
echo "1. BIGQUERY_PROJECT_ID - Your Google Cloud Project ID"
echo "2. BIGQUERY_DATASET - Dataset name (default: transformer_dbt_dev)"
echo "3. BIGQUERY_LOCATION - BigQuery location (default: US)"
echo "4. GOOGLE_APPLICATION_CREDENTIALS - Path to service account key file"
echo ""
echo "Example setup commands:"
echo "export BIGQUERY_PROJECT_ID='your-gcp-project-id'"
echo "export BIGQUERY_DATASET='transformer_dbt_dev'"
echo "export BIGQUERY_LOCATION='US'"
echo "export GOOGLE_APPLICATION_CREDENTIALS='/path/to/service-account-key.json'"
echo ""
echo "After setting these variables, you can run:"
echo "dbt compile --select fct_listing"
echo "dbt run --select fct_listing"
echo ""
echo "Note: Timeout has been increased to 30 minutes (1800 seconds) to handle complex queries."