{{
  config(
    materialized='table',
    cluster_by=['date_nk']
  )
}}

with date_spine as (
  {{ dbt_utils.date_spine(
    datepart="day",
    start_date="cast('2020-01-01' as date)",
    end_date="cast('2030-12-31' as date)"
  ) }}
),

final as (
  select
    -- Surrogate key
    {{ dbt_utils.generate_surrogate_key(['date_day']) }} as date_sk,
    
    -- Natural key (YYYYMMDD format)
    cast(format_date('%Y%m%d', date_day) as int64) as date_nk,
    
    -- Date attributes
    date_day as date_actual,
    extract(year from date_day) as year_actual,
    extract(quarter from date_day) as quarter_actual,
    extract(month from date_day) as month_actual,
    extract(week from date_day) as week_actual,
    extract(dayofweek from date_day) as day_of_week,
    extract(dayofyear from date_day) as day_of_year,
    
    -- Formatted date strings
    format_date('%B', date_day) as month_name,
    format_date('%A', date_day) as day_name,
    format_date('%Y-Q%q', date_day) as quarter_name,
    
    -- Business logic flags
    case when extract(dayofweek from date_day) in (1, 7) then true else false end as is_weekend,
    case when extract(dayofweek from date_day) between 2 and 6 then true else false end as is_weekday,
    
    -- Metadata
    current_timestamp() as dw_created_at,
    current_timestamp() as dw_updated_at
    
  from date_spine
)

select * from final
