{{
  config(
    materialized='table',
  )
}}

with src as (
  select
    id as product_id,
    code,
    name,
    slug,
    unit,
    title,
    active,
    featured,
    store_id,
    condition,
    gift_card,
    vendor_id,
    created_at,
    updated_at,
    product_cat,
    available_on,
    available_until,
    cancel_duration,
    tax_category_id,
    shipping_category_id,
    _airbyte_extracted_at as extracted_at
  from {{ source('shoppy_aurora','raw_spree_products') }}
)

select * from src


