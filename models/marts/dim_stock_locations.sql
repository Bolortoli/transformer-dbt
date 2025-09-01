{{ config(materialized='table') }}

select
  -- keys
  {{ dbt_utils.generate_surrogate_key(['id']) }} as stock_location_sk,
  id as stock_location_nk,
  id as stock_location_id,
  name,
  code,
  admin_name,
  vendor_id,
  created_at,
  updated_at,
  address1,
  address2,
  city,
  state_id,
  state_name,
  country_id,
  zipcode,
  phone,
  active,
  time_sheets,
  backorderable_default,
  propagate_all_variants,
  store_location_id,
  position
from {{ source('shoppy_aurora', 'raw_spree_stock_locations') }}