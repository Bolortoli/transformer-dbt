# Shoppy Data Warehouse - dbt Transformer

A comprehensive dbt (data build tool) project for transforming raw e-commerce data into clean, analytics-ready datasets for the Shoppy data warehouse.

## 🏗️ Project Overview

This dbt project transforms raw Spree Commerce data into dimensional models and fact tables optimized for analytics and reporting. The project follows modern data warehouse principles with staging, intermediate, and mart layers.

### Key Features
- **Incremental fact tables** with partitioning and clustering for optimal BigQuery performance
- **Dimensional modeling** with slowly changing dimension (SCD) support
- **Automated data quality testing** with comprehensive schema validation
- **Scheduled transformations** running every 5 minutes for real-time analytics
- **Cloud-native deployment** on Google Cloud Run

## 🚀 Quick Start

### Prerequisites
- Python 3.8+
- Google Cloud Platform account with BigQuery access
- dbt-bigquery adapter
- Access to Shoppy source databases

### Environment Setup

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd transformer-dbt
   ```

2. **Set up Python environment**
   ```bash
   python -m venv .venv
   source .venv/bin/activate  # On Windows: .venv\Scripts\activate
   pip install -r requirements.txt
   ```

3. **Configure environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your configurations
   ```

4. **Set up dbt profile**
   ```bash
   # Copy and customize the profiles.yml template
   cp profiles.yml ~/.dbt/profiles.yml
   # Edit with your BigQuery credentials
   ```

5. **Test the connection**
   ```bash
   dbt debug
   ```

## 📊 Project Structure

```
transformer-dbt/
├── models/
│   ├── staging/           # Raw data cleaning and basic transformations
│   │   ├── stg_spree_orders.sql
│   │   └── stg_spree_products.sql
│   └── marts/             # Business logic and final analytics tables
│       ├── dim_*.sql      # Dimension tables
│       ├── fct_*.sql      # Fact tables
│       └── schema.yml     # Tests and documentation
├── dbt_project.yml        # dbt project configuration
├── packages.yml           # dbt package dependencies
├── profiles.yml           # Database connection settings (template)
├── deploy.sh              # Manual deployment script
├── scheduler.sh           # Automated scheduling script
└── cloud-deploy.sh        # Google Cloud deployment
```

### Data Models

#### Staging Layer (`staging/`)
- **stg_spree_orders**: Cleaned and standardized order data
- **stg_spree_products**: Product catalog with basic transformations

#### Marts Layer (`marts/`)

**Dimension Tables:**
- `dim_dates`: Date dimension with business calendar attributes
- `dim_product`: Product master data with hierarchies
- `dim_variants`: Product variant details
- `dim_stores`: Store locations and attributes
- `dim_vendors`: Vendor information
- `dim_taxons`: Product taxonomy and categories
- `dim_stock_locations`: Inventory location data
- `dim_websites`: Website configuration data
- `dim_listing_events`: Event tracking dimension

**Fact Tables:**
- `fct_listing`: Core listing facts with incremental loading
- `fct_orders_products`: Order line item facts

## 🛠️ Development Workflow

### Running Transformations

**Development Environment:**
```bash
# Run all models
dbt run

# Run specific model
dbt run --select fct_listing

# Run with tests
dbt build
```

**Run transformer locally:**
```bash
cd transformer-dbt                       
. .venv/bin/activate
set -a; source .env; set +a
dbt run -s fct_listing --target "$TARGET"
```

**Production Deployment:**
```bash
./deploy.sh prod run
```

### Testing

```bash
# Run all tests
dbt test

# Test specific model
dbt test --select fct_listing

# Run tests with data freshness checks
dbt test --select +freshness
```

### Documentation

```bash
# Generate and serve documentation
dbt docs generate
dbt docs serve
```

## 🔄 Automated Scheduling

The project includes automated scheduling to run transformations every 5 minutes.

### Setup Scheduler
```bash
# Development environment
./scheduler.sh dev setup

# Production environment
./scheduler.sh prod setup
```

### Monitor Scheduler
```bash
# Check status
./scheduler.sh status

# View logs
tail -f logs/scheduler_$(date +%Y%m%d).log
```

## ☁️ Cloud Deployment

Deploy to Google Cloud Run for serverless execution:

```bash
# Deploy to cloud
./cloud-deploy.sh

# Check deployment status
gcloud run services describe dbt-transformer --region=us-central1
```

## 🔧 Configuration

### Environment Variables (.env)
```bash
# BigQuery Configuration
BIGQUERY_PROJECT_ID=your-project-id
BIGQUERY_DATASET=transformer_dbt_prod
BIGQUERY_LOCATION=US

# Authentication
GOOGLE_APPLICATION_CREDENTIALS=path/to/service-account.json

# dbt Configuration
DBT_PROFILES_DIR=.
DBT_TARGET=prod
```

### Key dbt Configurations

- **Materialization Strategy**: Staging as views, marts as tables, facts as incremental
- **Partitioning**: Fact tables partitioned by date for performance
- **Clustering**: Strategic clustering on commonly filtered columns
- **Testing**: Comprehensive data quality tests on all models

## 🧪 Data Quality

The project includes extensive data quality testing:

- **Uniqueness tests** on surrogate keys
- **Not null tests** on critical columns
- **Referential integrity** between fact and dimension tables
- **Custom business rule validation**
- **Data freshness monitoring**

## 🤝 Contributing

### For Data Engineers

1. **Clone and setup** the development environment
2. **Create feature branches** for new models or changes
3. **Follow naming conventions**:
   - Staging: `stg_{source}_{table}`
   - Dimensions: `dim_{business_entity}`
   - Facts: `fct_{business_process}`
4. **Add tests and documentation** for all new models
5. **Test locally** before pushing changes
6. **Submit pull requests** with clear descriptions

### Code Review Guidelines

- Verify SQL follows company standards
- Ensure proper testing coverage
- Check documentation completeness
- Validate performance implications
- Review incremental model logic

## 📝 Additional Documentation

- [Scheduler Setup Guide](SCHEDULER_SETUP.md) - Detailed scheduling configuration
- [Deployment Guide](DEPLOYMENT.md) - Cloud deployment instructions
- [Performance Optimization](fct_listing_performance_optimization.md) - Query optimization notes

## 🆘 Troubleshooting

### Common Issues

1. **Connection errors**: Check `profiles.yml` and credentials
2. **Permission denied**: Verify BigQuery IAM permissions
3. **Model failures**: Check `target/run_results.json` for details
4. **Performance issues**: Review partitioning and clustering strategy

### Getting Help

- Check the [dbt documentation](https://docs.getdbt.com/)
- Review project logs in `logs/dbt.log`
- Contact the data team for project-specific questions

---

**Last Updated**: September 1, 2025  
**Project Version**: 1.0.0  
**dbt Version**: 1.5+  
**Database**: Google BigQuery