# DBT Transformer Scheduler Setup

This guide explains how to set up automated scheduling for the dbt transformations to run every 5 minutes, ensuring continuous data processing.

## 🚨 Problem Solved

The transformer was not running continuously (last update was 6 days ago). This scheduler ensures:
- **Automatic execution** every 5 minutes
- **Continuous data processing** without manual intervention  
- **Robust error handling** and logging
- **Easy management** of scheduling

## 🛠️ Quick Setup

### 1. Prerequisites
Ensure your environment is properly configured:
```bash
# Navigate to the transformer directory
cd transformer-dbt

# Verify .env file exists with proper configuration
cat .env

# Test manual deployment works
./deploy.sh dev run
```

### 2. Setup Automated Scheduling

**For Development Environment:**
```bash
# Setup cron job to run every 5 minutes
./scheduler.sh dev setup
```

**For Production Environment:**
```bash
# Setup cron job for production
./scheduler.sh prod setup
```

### 3. Verify Scheduling is Active
```bash
# Check if cron job is running
./scheduler.sh status

# View recent logs
tail -f logs/scheduler_$(date +%Y%m%d).log
```

## 📋 Scheduler Commands

The `scheduler.sh` script supports multiple commands:

| Command | Description | Example |
|---------|-------------|---------|
| `run` | Execute transformation once | `./scheduler.sh dev run` |
| `setup` | Setup cron job for scheduled runs | `./scheduler.sh prod setup` |
| `remove` | Remove existing cron job | `./scheduler.sh remove` |
| `status` | Check cron job status | `./scheduler.sh status` |
| `help` | Show help information | `./scheduler.sh help` |

## ⚙️ Configuration Details

### Scheduling Frequency
- **Frequency**: Every 5 minutes (`*/5 * * * *`)
- **Environment**: Configurable (dev/staging/prod)
- **Logging**: Automatic with daily log rotation

### Log Files Location
```
transformer-dbt/logs/
├── scheduler_YYYYMMDD.log    # Daily scheduler logs
└── dbt.log                   # DBT execution logs
```

### Environment Variables Required
The scheduler requires the same environment variables as the deployment script:
- `BIGQUERY_PROJECT_ID` - Your GCP project ID
- `GOOGLE_APPLICATION_CREDENTIALS` - Path to service account JSON
- `BIGQUERY_DATASET` - Target dataset (optional, defaults per environment)
- `BIGQUERY_LOCATION` - BigQuery region (optional, defaults to US)

## 🔍 Monitoring and Troubleshooting

### Check Scheduler Status
```bash
# Verify cron job is active
./scheduler.sh status

# View current cron jobs
crontab -l
```

### View Logs
```bash
# Today's scheduler logs
tail -f logs/scheduler_$(date +%Y%m%d).log

# All recent logs
ls -la logs/scheduler_*.log

# DBT-specific logs
tail -f logs/dbt.log
```

### Common Issues and Solutions

**Issue: "No cron job found"**
```bash
# Solution: Setup the cron job
./scheduler.sh prod setup
```

**Issue: "Environment variables not found"**
```bash
# Solution: Verify .env file exists and has correct values
cat .env
source .env
```

**Issue: "Deploy script fails"**
```bash
# Solution: Test manual deployment first
./deploy.sh dev run

# Check BigQuery credentials
dbt debug
```

**Issue: "Permission denied"**
```bash
# Solution: Ensure scripts are executable
chmod +x scheduler.sh deploy.sh
```

## 🚀 Production Deployment

### Step-by-Step Production Setup

1. **Verify Production Environment**
   ```bash
   # Test production deployment manually first
   ./deploy.sh prod run
   ```

2. **Setup Production Scheduler**
   ```bash
   # Setup automated scheduling for production
   ./scheduler.sh prod setup
   ```

3. **Verify Everything is Working**
   ```bash
   # Check cron job status
   ./scheduler.sh status
   
   # Monitor first few runs
   tail -f logs/scheduler_$(date +%Y%m%d).log
   ```

### Production Best Practices

- **Monitor Logs**: Regularly check scheduler logs for failures
- **Cost Control**: Production profile has 1GB query limit to control costs  
- **Performance**: Uses batch priority and extended timeouts
- **Backup**: Keep manual deployment capability as backup

## 🔧 Advanced Configuration

### Custom Scheduling Frequency

To change the scheduling frequency, edit the `scheduler.sh` file:

```bash
# Line 71 in scheduler.sh
local cron_schedule="*/5 * * * *"  # Every 5 minutes

# Examples:
# */1 * * * *   # Every minute
# */10 * * * *  # Every 10 minutes  
# 0 * * * *     # Every hour
# 0 */6 * * *   # Every 6 hours
```

### Multiple Environment Scheduling

You can run schedulers for multiple environments simultaneously:

```bash
# Setup schedulers for different environments
./scheduler.sh dev setup
./scheduler.sh staging setup  
./scheduler.sh prod setup

# Each will have its own cron job and logs
```

### Log Retention

By default, logs are kept indefinitely. To implement log rotation:

```bash
# Add to your system's logrotate configuration
sudo nano /etc/logrotate.d/dbt-scheduler

# Content:
/path/to/transformer-dbt/logs/scheduler_*.log {
    daily
    rotate 30
    compress
    missingok
    notifempty
    create 644 user user
}
```

## 📊 Expected Results

Once the scheduler is set up and running:

### Immediate Results
- ✅ Cron job active and running every 5 minutes
- ✅ Automated dbt transformations executing
- ✅ Logs being generated with timestamps

### Within 1 Hour
- ✅ Multiple successful transformation runs logged
- ✅ Incremental models updating with new data
- ✅ No manual intervention required

### Ongoing Benefits
- ✅ **Continuous data processing** - No more 6-day gaps
- ✅ **Real-time insights** - Data always up-to-date  
- ✅ **Automated monitoring** - Logs track all executions
- ✅ **Error recovery** - Failed runs are logged and retried

## 🆘 Support

### Getting Help
```bash
# Show scheduler help
./scheduler.sh help

# Show deployment help
./deploy.sh help
```

### Emergency Procedures

**Stop All Scheduling:**
```bash
./scheduler.sh remove
```

**Manual Override:**
```bash
# Run transformations manually if needed
./deploy.sh prod run
```

**Reset Everything:**
```bash
# Remove cron job
./scheduler.sh remove

# Clear logs (optional)
rm -f logs/scheduler_*.log

# Setup fresh
./scheduler.sh prod setup
```

---

## 🎯 Success Criteria

✅ **Scheduler Active**: Cron job running every 5 minutes  
✅ **Transformations Working**: DBT models executing successfully  
✅ **Logs Generated**: Daily logs showing execution history  
✅ **Data Fresh**: No more multi-day gaps in data processing  

The transformer is now running **non-stop** as required! 🚀