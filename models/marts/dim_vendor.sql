{{
  config(
    materialized='table',
    cluster_by=['vendor_id']
  )
}}

with vendors as (
  select distinct
    vendor_id,
    created_at,
    updated_at
  from {{ ref('stg_spree_products') }}
  where vendor_id is not null
),

final as (
  select
    -- Surrogate key
    {{ dbt_utils.generate_surrogate_key(['vendor_id']) }} as vendor_sk,
    
    -- Natural key
    vendor_id as vendor_nk,
    
    -- Vendor attributes (placeholder - would need actual vendor table)
    cast(vendor_id as string) as vendor_name,
    'Active' as vendor_status,
    
    -- Dates
    min(created_at) as first_product_created_at,
    max(updated_at) as last_product_updated_at,
    
    -- Metadata
    current_timestamp() as dw_created_at,
    current_timestamp() as dw_updated_at
    
  from vendors
  group by vendor_id
)

select * from final
