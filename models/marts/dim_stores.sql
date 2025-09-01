{{
  config(
    materialized='table',
    cluster_by=['store_nk']
  )
}}

with stores_from_orders as (
  select distinct
    store_id,
    created_at,
    updated_at
  from {{ ref('stg_spree_orders') }}
  where store_id is not null
),

stores_from_products as (
  select distinct
    store_id,
    created_at,
    updated_at
  from {{ ref('stg_spree_products') }}
  where store_id is not null
),

all_stores as (
  select * from stores_from_orders
  union distinct
  select * from stores_from_products
),

final as (
  select
    -- Surrogate key
    {{ dbt_utils.generate_surrogate_key(['store_id']) }} as store_sk,

    -- Natural key
    store_id as store_nk,

    -- Store attributes (placeholder - would need actual store table)
    concat('Store ', cast(store_id as string)) as store_name,
    'Active' as store_status,
    'Unknown' as store_region,

    -- Dates
    min(created_at) as first_activity_date,
    max(updated_at) as last_activity_date,

    -- Metadata
    current_timestamp() as dw_created_at,
    current_timestamp() as dw_updated_at

  from all_stores
  group by store_nk
)

select * from final
