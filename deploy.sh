#!/bin/bash

# dbt Deployment Script
# Usage: ./deploy.sh [environment] [command]
# Example: ./deploy.sh prod run

set -e

# Default values
ENVIRONMENT=${1:-dev}
COMMAND=${2:-run}

echo "🚀 Starting dbt deployment for environment: $ENVIRONMENT"

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    echo "❌ Error: Invalid environment '$ENVIRONMENT'. Must be one of: dev, staging, prod"
    exit 1
fi

# Set environment variables
export DBT_TARGET=$ENVIRONMENT

# Load environment-specific configurations
if [[ "$ENVIRONMENT" == "prod" ]]; then
    export BIGQUERY_DATASET=transformer_dbt_prod
elif [[ "$ENVIRONMENT" == "staging" ]]; then
    export BIGQUERY_DATASET=transformer_dbt_staging
else
    export BIGQUERY_DATASET=transformer_dbt_dev
fi

echo "📝 Using configuration:"
echo "   Target: $DBT_TARGET"
echo "   Dataset: $BIGQUERY_DATASET"

# Check for required environment variables
if [[ -z "$BIGQUERY_PROJECT_ID" ]]; then
    echo "❌ Error: BIGQUERY_PROJECT_ID environment variable is required"
    exit 1
fi

if [[ -z "$GOOGLE_APPLICATION_CREDENTIALS" ]]; then
    echo "❌ Error: GOOGLE_APPLICATION_CREDENTIALS environment variable is required"
    exit 1
fi

# Install dependencies
echo "📦 Installing dbt dependencies..."
dbt deps

# Debug connection
echo "🔍 Testing connection..."
dbt debug --target $ENVIRONMENT

# Execute command based on argument
case $COMMAND in
    "run")
        echo "▶️  Running dbt models..."
        dbt run --target $ENVIRONMENT
        ;;
    "test")
        echo "🧪 Running dbt tests..."
        dbt test --target $ENVIRONMENT
        ;;
    "build")
        echo "🏗️  Building dbt project (run + test)..."
        dbt build --target $ENVIRONMENT
        ;;
    "compile")
        echo "🔧 Compiling dbt models..."
        dbt compile --target $ENVIRONMENT
        ;;
    "seed")
        echo "🌱 Loading seed data..."
        dbt seed --target $ENVIRONMENT
        ;;
    "docs")
        echo "📖 Generating documentation..."
        dbt docs generate --target $ENVIRONMENT
        dbt docs serve
        ;;
    "fresh")
        echo "🔄 Checking source freshness..."
        dbt source freshness --target $ENVIRONMENT
        ;;
    "full-refresh")
        echo "🔄 Full refresh deployment..."
        dbt run --target $ENVIRONMENT --full-refresh
        ;;
    *)
        echo "❌ Error: Unknown command '$COMMAND'"
        echo "Available commands: run, test, build, compile, seed, docs, fresh, full-refresh"
        exit 1
        ;;
esac

echo "✅ dbt deployment completed successfully for environment: $ENVIRONMENT"