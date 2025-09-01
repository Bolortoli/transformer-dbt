#!/bin/bash

# DBT Transformation Scheduler
# This script runs the dbt transformations every 5 minutes
# Usage: ./scheduler.sh [environment]

set -e

# Default environment
ENVIRONMENT=${1:-dev}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
LOG_FILE="$LOG_DIR/scheduler_$(date +%Y%m%d).log"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Function to log with timestamp
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to run dbt deployment
run_dbt_deployment() {
    local env=$1
    local start_time=$(date +%s)
    
    log_message "🚀 Starting scheduled dbt run for environment: $env"
    
    # Source environment variables
    if [[ -f "$SCRIPT_DIR/.env" ]]; then
        set -a
        source "$SCRIPT_DIR/.env"
        set +a
        log_message "📝 Environment variables loaded from .env"
    else
        log_message "⚠️  No .env file found - using system environment variables"
    fi
    
    # Check required environment variables
    if [[ -z "$BIGQUERY_PROJECT_ID" ]]; then
        log_message "❌ Error: BIGQUERY_PROJECT_ID environment variable is required"
        return 1
    fi
    
    if [[ -z "$GOOGLE_APPLICATION_CREDENTIALS" ]]; then
        log_message "❌ Error: GOOGLE_APPLICATION_CREDENTIALS environment variable is required"
        return 1
    fi
    
    # Change to dbt project directory
    cd "$SCRIPT_DIR"
    
    # Run the deployment
    if ./deploy.sh "$env" run >> "$LOG_FILE" 2>&1; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log_message "✅ dbt deployment completed successfully in ${duration}s"
        return 0
    else
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log_message "❌ dbt deployment failed after ${duration}s - check logs for details"
        return 1
    fi
}

# Function to setup cron job
setup_cron_job() {
    local env=${1:-dev}
    local cron_schedule="*/5 * * * *"  # Every 5 minutes
    local script_path="$SCRIPT_DIR/scheduler.sh"
    local cron_command="$script_path $env"
    
    log_message "🕒 Setting up cron job for environment: $env"
    log_message "📅 Schedule: Every 5 minutes ($cron_schedule)"
    
    # Create temporary cron file
    local temp_cron="/tmp/dbt_cron_$$.tmp"
    
    # Get existing cron jobs (excluding this one)
    crontab -l 2>/dev/null | grep -v "$script_path" > "$temp_cron" || true
    
    # Add new cron job
    echo "$cron_schedule $cron_command" >> "$temp_cron"
    
    # Install new cron table
    if crontab "$temp_cron"; then
        log_message "✅ Cron job installed successfully"
        log_message "📋 Current cron jobs:"
        crontab -l | tee -a "$LOG_FILE"
    else
        log_message "❌ Failed to install cron job"
        rm -f "$temp_cron"
        return 1
    fi
    
    # Clean up
    rm -f "$temp_cron"
}

# Function to remove cron job
remove_cron_job() {
    local script_path="$SCRIPT_DIR/scheduler.sh"
    local temp_cron="/tmp/dbt_cron_remove_$$.tmp"
    
    log_message "🗑️  Removing cron job"
    
    # Get existing cron jobs (excluding this one)
    if crontab -l 2>/dev/null | grep -v "$script_path" > "$temp_cron"; then
        crontab "$temp_cron"
        log_message "✅ Cron job removed successfully"
    else
        log_message "ℹ️  No cron job found to remove"
    fi
    
    rm -f "$temp_cron"
}

# Function to check cron job status
check_cron_status() {
    local script_path="$SCRIPT_DIR/scheduler.sh"
    
    log_message "🔍 Checking cron job status"
    
    if crontab -l 2>/dev/null | grep -q "$script_path"; then
        log_message "✅ Cron job is active:"
        crontab -l | grep "$script_path" | tee -a "$LOG_FILE"
    else
        log_message "❌ No active cron job found"
    fi
}

# Main execution
# Handle single-word commands (status, remove, help) when no environment is specified
if [[ "$1" =~ ^(status|remove|help)$ ]] && [[ -z "$2" ]]; then
    ENVIRONMENT="dev"  # Default environment
    COMMAND="$1"
else
    COMMAND="${2:-run}"
fi

# Handle help command specially
if [[ "$ENVIRONMENT" == "help" ]] || [[ "$COMMAND" == "help" ]]; then
    echo "Usage: $0 [environment] [command]"
    echo ""
    echo "Environments: dev, staging, prod (default: dev)"
    echo "Commands:"
    echo "  run     - Run dbt transformation once (default)"
    echo "  setup   - Setup cron job for scheduled runs every 5 minutes"
    echo "  remove  - Remove existing cron job"
    echo "  status  - Check cron job status"
    echo "  help    - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 dev run      # Run once in dev environment"
    echo "  $0 prod setup   # Setup cron job for prod environment"
    echo "  $0 status       # Check if cron job is running"
    echo "  $0 remove       # Remove cron job"
    exit 0
fi

case "$COMMAND" in
    "run")
        run_dbt_deployment "$ENVIRONMENT"
        ;;
    "setup")
        setup_cron_job "$ENVIRONMENT"
        ;;
    "remove")
        remove_cron_job
        ;;
    "status")
        check_cron_status
        ;;
    *)
        log_message "❌ Unknown command: $COMMAND"
        log_message "Use '$0 help' for usage information"
        exit 1
        ;;
esac