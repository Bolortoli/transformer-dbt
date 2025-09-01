{{ config(materialized='table') }}

select
  -- keys
  {{ dbt_utils.generate_surrogate_key(['id']) }} as product_sk,
  id as product_nk,
  id as product_id,
  name,
  slug,
  tax_category_id,
  shipping_category_id,
  description,
  unit
from {{ source('shoppy_aurora', 'raw_spree_products') }}
