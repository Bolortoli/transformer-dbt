{{ config(materialized='table') }}

select
  -- keys
  {{ dbt_utils.generate_surrogate_key(['id']) }} as vendor_sk,
  id as vendor_nk,

  -- attributes
  id as vendor_id,
  name,
  address,
  phone,
  email,
  created_at,
  updated_at,
  `register`,
  vat,
  ebarimt_type,
  data,
  name_en,
  website,
  parent_id,
  manager,
  note1,
  note2,
  note3,
  note4,
  note5,
  note6,
  note7,
  note8,
  category,
  is_verified,
  is_city_tax_payer,
  coalesce(is_individual, false) as is_individual,
  employee_count,
  description,
  country_id,
  state_id,
  district_id,
  quarter_id,
  zip_id,
  coalesce(impressions_count, 0) as impressions_count,
  coalesce(pos, false) as pos,
  currency,
  personal_number,
  tax_number
from {{ source('shoppy_aurora', 'raw_spree_vendors') }}

