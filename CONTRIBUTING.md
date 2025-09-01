# Contributing to Shoppy Data Warehouse - dbt Transformer

Thank you for your interest in contributing to our dbt transformation project! This guide will help you get started and ensure smooth collaboration.

## 🚀 Getting Started

### Prerequisites

Before you begin, ensure you have:
- Python 3.8+ installed
- Git configured with your name and email
- Access to the Shoppy BigQuery datasets
- dbt fundamentals knowledge

### Initial Setup

1. **Fork and clone the repository**
   ```bash
   git clone https://github.com/your-username/transformer-dbt.git
   cd transformer-dbt
   ```

2. **Set up your development environment**
   ```bash
   python -m venv .venv
   source .venv/bin/activate
   pip install -r requirements.txt
   ```

3. **Configure your environment**
   ```bash
   cp .env.example .env
   # Edit .env with your development configurations
   ```

4. **Test your setup**
   ```bash
   dbt debug
   ```

## 🔄 Development Workflow

### Branch Strategy

- **main**: Production-ready code
- **develop**: Development integration branch
- **feature/**: New features or model additions
- **fix/**: Bug fixes and corrections
- **docs/**: Documentation updates

### Making Changes

1. **Create a feature branch**
   ```bash
   git checkout -b feature/new-dimension-table
   ```

2. **Make your changes following our conventions**

3. **Test your changes locally**
   ```bash
   dbt run --select +your_model
   dbt test --select your_model
   ```

4. **Commit with descriptive messages**
   ```bash
   git add .
   git commit -m "feat: add dim_customer dimension table

   - Add customer dimension with SCD Type 2 logic
   - Include comprehensive testing suite
   - Add documentation and business definitions"
   ```

5. **Push and create pull request**
   ```bash
   git push origin feature/new-dimension-table
   ```

## 📏 Code Standards

### Naming Conventions

**Models:**
- Staging: `stg_{source_system}_{table_name}.sql`
- Intermediate: `int_{business_area}_{description}.sql`
- Dimensions: `dim_{business_entity}.sql`
- Facts: `fct_{business_process}.sql`

**Columns:**
- Use `snake_case` for all column names
- Surrogate keys: `{table_name}_sk`
- Natural keys: `{table_name}_nk`
- Foreign keys: `{referenced_table}_sk`

**Examples:**
```sql
-- Good
dim_customer.sql
fct_sales.sql
stg_shopify_orders.sql

-- Avoid
Customer_Dimension.sql
sales_fact.sql
shopify-orders-staging.sql
```

### SQL Style Guide

**General Formatting:**
```sql
-- Use consistent indentation (4 spaces)
select
    customer_sk,
    customer_nk,
    first_name,
    last_name,
    email,
    created_at,
    updated_at
from {{ ref('stg_customers') }}
where is_active = true
```

**CTEs and Subqueries:**
```sql
-- Use descriptive CTE names
with customer_orders as (
    select
        customer_id,
        count(*) as total_orders,
        sum(order_total) as lifetime_value
    from {{ ref('fct_orders') }}
    group by customer_id
),

customer_segments as (
    select
        customer_id,
        case
            when lifetime_value >= 1000 then 'VIP'
            when lifetime_value >= 500 then 'Gold'
            else 'Standard'
        end as customer_segment
    from customer_orders
)

select * from customer_segments
```

**Jinja Usage:**
```sql
-- Use Jinja for dynamic logic
select
    product_id,
    product_name,
    {% if var('include_price', false) %}
    unit_price,
    {% endif %}
    created_at
from {{ ref('stg_products') }}
{% if is_incremental() %}
    where updated_at > (select max(updated_at) from {{ this }})
{% endif %}
```

## 🧪 Testing Requirements

### Required Tests for New Models

**All Models:**
- Not null tests on primary keys
- Uniqueness tests on primary keys

**Dimension Tables:**
- Referential integrity tests
- Valid value tests for categorical columns
- Data freshness tests

**Fact Tables:**
- Relationship tests to dimensions
- Custom business logic validation
- Data volume checks

### Test Examples

```yaml
# schema.yml
version: 2

models:
  - name: dim_customer
    description: "Customer dimension with SCD Type 2 logic"
    columns:
      - name: customer_sk
        description: "Surrogate key for customer"
        tests:
          - not_null
          - unique

      - name: customer_nk
        description: "Natural key from source system"
        tests:
          - not_null

      - name: customer_status
        description: "Current customer status"
        tests:
          - accepted_values:
              values: ['Active', 'Inactive', 'Pending']
```

## 📖 Documentation Standards

### Model Documentation

Every model must include:
- Business purpose and description
- Data sources and lineage
- Refresh frequency and dependencies
- Column definitions and business rules
- Known limitations or assumptions

### Documentation Template

```yaml
models:
  - name: fct_sales
    description: |
      Daily sales fact table containing all completed transactions.
      
      **Business Logic:**
      - Includes only completed orders (status = 'completed')
      - Revenue calculated as quantity * unit_price - discounts
      - Updated daily at 6 AM UTC
      
      **Data Sources:**
      - Orders: Shopify API
      - Products: Internal product catalog
      - Customers: CRM system
    
    columns:
      - name: sale_sk
        description: "Unique identifier for each sale record"
        
      - name: order_date_sk
        description: "Foreign key to dim_dates for order date"
        
      - name: revenue_amount
        description: "Total revenue for the sale (quantity * unit_price - discounts)"
```

## 🚦 Pull Request Process

### Before Submitting

**Checklist:**
- [ ] Code follows style guidelines
- [ ] All tests pass locally
- [ ] New models have proper documentation
- [ ] Schema changes are documented
- [ ] Performance implications considered

### PR Description Template

```markdown
## Description
Brief description of changes made.

## Type of Change
- [ ] New feature (dimension/fact table)
- [ ] Bug fix
- [ ] Performance improvement
- [ ] Documentation update
- [ ] Refactoring

## Models Changed
- model_name_1: Description of changes
- model_name_2: Description of changes

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed

## Performance Impact
Describe any performance implications.

## Documentation
- [ ] Updated model documentation
- [ ] Updated README if needed
```

### Review Process

1. **Automated checks** run on all PRs
2. **Peer review** by another data engineer
3. **Data quality validation** in staging environment
4. **Performance review** for significant changes
5. **Final approval** by data team lead

## 🎯 Best Practices

### Performance Optimization

**Incremental Models:**
```sql
{{ config(
    materialized='incremental',
    unique_key=['order_id', 'product_id'],
    on_schema_change='append_new_columns',
    partition_by={'field': 'order_date', 'data_type': 'date'},
    cluster_by=['customer_id', 'product_id']
) }}
```

**Query Optimization:**
- Use appropriate WHERE clauses in staging models
- Implement proper indexing strategies
- Avoid SELECT * in production models
- Use incremental loading for large datasets

### Data Quality

**Implement checks for:**
- Data completeness and accuracy
- Business rule validation
- Data freshness monitoring
- Anomaly detection

### Version Control

**Commit Messages:**
- Use conventional commit format
- Include context and reasoning
- Reference related issues/tickets

## 🆘 Getting Help

### Resources

- **dbt Documentation**: https://docs.getdbt.com/
- **Internal Wiki**: [Link to internal documentation]
- **Slack Channel**: #data-engineering
- **Team Meetings**: Tuesdays 10 AM for dbt office hours

### Common Issues

**Connection Problems:**
1. Check your `.env` configuration
2. Verify BigQuery permissions
3. Test with `dbt debug`

**Model Failures:**
1. Check `target/run_results.json`
2. Review logs in `logs/dbt.log`
3. Test dependencies with `dbt run --select +model_name`

**Performance Issues:**
1. Review query execution plans
2. Check partitioning and clustering
3. Consider incremental materialization

## 🏆 Recognition

Contributors who consistently follow these guidelines and make valuable contributions will be recognized in:
- Monthly team meetings
- Project documentation
- Internal newsletters

Thank you for contributing to our data transformation success! 🎉