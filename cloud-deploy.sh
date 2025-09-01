#!/bin/bash

# Google Cloud Deployment Script for DBT Transformer
# This script deploys the dbt transformer to run on Google Cloud

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ID="${BIGQUERY_PROJECT_ID:-cody-439704}"

# Map BigQuery location to Cloud Run region
BQ_LOCATION="${BIGQUERY_LOCATION:-EU}"
case "$BQ_LOCATION" in
    "EU"|"europe") REGION="europe-west1" ;;
    "US"|"us") REGION="us-central1" ;;
    "asia") REGION="asia-east1" ;;
    *) REGION="europe-west1" ;;  # Default fallback
esac

SERVICE_NAME="dbt-transformer"
CLOUD_RUN_SERVICE="dbt-transformer-service"

echo "🚀 Starting Google Cloud deployment for dbt transformer"
echo "   Project: $PROJECT_ID"
echo "   Region: $REGION"

# Check if gcloud is installed and authenticated
if ! command -v gcloud &> /dev/null; then
    echo "❌ Error: gcloud CLI is required but not installed"
    echo "   Install from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Check authentication
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n 1 > /dev/null; then
    echo "❌ Error: Not authenticated with gcloud"
    echo "   Run: gcloud auth login"
    exit 1
fi

# Set the project
echo "📝 Setting project: $PROJECT_ID"
gcloud config set project "$PROJECT_ID"

# Enable required APIs
echo "🔧 Enabling required Google Cloud APIs..."
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable cloudscheduler.googleapis.com
gcloud services enable bigquery.googleapis.com

# Create a simple web service for Cloud Run
echo "🌐 Creating web service for Cloud Run..."
cat > web_service.py <<'EOF'
from flask import Flask, request, jsonify
import subprocess
import os
import logging
import threading
from datetime import datetime

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)

# Global variable to track last execution
last_execution = {"time": None, "status": None, "message": None}

@app.route('/', methods=['GET'])
def health_check():
    return jsonify({
        "status": "healthy",
        "service": "dbt-transformer",
        "timestamp": datetime.now().isoformat(),
        "last_execution": last_execution
    })

@app.route('/run', methods=['POST', 'GET'])
def run_dbt():
    def execute_dbt():
        global last_execution
        try:
            logging.info("Starting dbt deployment...")
            last_execution["time"] = datetime.now().isoformat()
            last_execution["status"] = "running"
            
            # Set environment variables
            env = os.environ.copy()
            env['DBT_TARGET'] = 'prod'
            env['BIGQUERY_DATASET'] = 'transformer_dbt_prod'
            
            # Run dbt deployment
            result = subprocess.run(
                ['./deploy.sh', 'prod', 'run'], 
                capture_output=True, 
                text=True,
                env=env,
                timeout=1200  # 20 minutes timeout
            )
            
            if result.returncode == 0:
                logging.info("dbt deployment completed successfully")
                last_execution["status"] = "success"
                last_execution["message"] = "Deployment completed successfully"
            else:
                logging.error(f"dbt deployment failed: {result.stderr}")
                last_execution["status"] = "error"
                last_execution["message"] = f"Deployment failed: {result.stderr[-500:]}"
                
        except Exception as e:
            logging.error(f"Error running dbt: {str(e)}")
            last_execution["status"] = "error"
            last_execution["message"] = f"Error: {str(e)}"
    
    # Run in background thread to avoid timeout
    thread = threading.Thread(target=execute_dbt)
    thread.start()
    
    return jsonify({
        "status": "started",
        "message": "dbt deployment started in background",
        "timestamp": datetime.now().isoformat()
    })

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port, debug=False)
EOF

# Create Dockerfile for Cloud Run
echo "📦 Creating Dockerfile for Cloud Run deployment..."
cat > Dockerfile <<EOF
FROM python:3.12-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \\
    git \\
    curl \\
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Install dbt and Flask
RUN pip install dbt-core dbt-bigquery flask gunicorn

# Copy dbt project files
COPY . .

# Make scripts executable
RUN chmod +x deploy.sh

# Set environment variables
ENV DBT_PROFILES_DIR=/app
ENV PYTHONPATH=/app
ENV PORT=8080

# Expose port
EXPOSE 8080

# Run web service with Python directly
CMD ["python", "web_service.py"]
EOF


# Create requirements.txt if it doesn't exist
if [[ ! -f requirements.txt ]]; then
    echo "📄 Creating requirements.txt..."
    cat > requirements.txt <<EOF
dbt-core>=1.5.0
dbt-bigquery>=1.5.0
google-cloud-bigquery>=3.0.0
google-auth>=2.0.0
flask>=2.0.0
gunicorn>=20.0.0
EOF
fi

# Deploy using gcloud run deploy command instead of YAML
echo "☁️ Preparing Cloud Run deployment..."

# Build and push Docker image
echo "🔨 Building Docker image..."
gcloud builds submit --tag gcr.io/$PROJECT_ID/$SERVICE_NAME .

# Deploy to Cloud Run with direct command
echo "🚀 Deploying to Cloud Run..."
gcloud run deploy $CLOUD_RUN_SERVICE \
    --image=gcr.io/$PROJECT_ID/$SERVICE_NAME:latest \
    --region=$REGION \
    --platform=managed \
    --allow-unauthenticated \
    --memory=4Gi \
    --cpu=2 \
    --timeout=3600 \
    --max-instances=1 \
    --set-env-vars="BIGQUERY_PROJECT_ID=$PROJECT_ID,BIGQUERY_LOCATION=$BQ_LOCATION,BIGQUERY_DATASET=transformer_dbt_prod,DBT_TARGET=prod" \
    --no-cpu-throttling \
    --execution-environment=gen2

# Note: Scheduling is now handled internally by the container's cron job
echo "⏰ Scheduling handled internally by container cron (every 5 minutes)"

echo "✅ Cloud deployment completed successfully!"
echo ""
echo "📊 Deployment Summary:"
echo "   Cloud Run Service: $CLOUD_RUN_SERVICE"
echo "   Scheduler Job: dbt-transformer-scheduler (every 5 minutes)"
echo "   Region: $REGION"
echo "   Project: $PROJECT_ID"
echo ""
echo "🔍 Monitor your deployment:"
echo "   Cloud Run: https://console.cloud.google.com/run/detail/$REGION/$CLOUD_RUN_SERVICE"
echo "   Cloud Scheduler: https://console.cloud.google.com/cloudscheduler"
echo "   BigQuery: https://console.cloud.google.com/bigquery"
echo ""
echo "🚀 Your dbt transformer is now running in the cloud every 5 minutes!"