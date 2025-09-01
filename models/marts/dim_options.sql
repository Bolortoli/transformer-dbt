{{ config(materialized='table') }}

-- Dimension table for product options combining option types and option values
-- This table provides a comprehensive view of all available product options
-- with their hierarchical relationship (option type -> option value)

select
  -- Surrogate keys
  {{ dbt_utils.generate_surrogate_key(['ov.id', 'ot.id']) }} as option_sk,
  
  -- Option value identifiers
  ov.id as option_value_nk,
  ov.id as option_value_id,
  ov.code as option_value_code,
  ov.name as option_value_name,
  ov.presentation as option_value_presentation,
  ov.position as option_value_position,
  
  -- Option type identifiers  
  ot.id as option_type_nk,
  ot.id as option_type_id,
  ot.name as option_type_name,
  ot.presentation as option_type_presentation,
  ot.position as option_type_position,
  ot.website_id,
  
  -- Combined descriptors
  concat(ot.name, ': ', ov.name) as option_full_name,
  concat(ot.presentation, ': ', ov.presentation) as option_full_presentation,
  
  -- Metadata
  ov.created_at as option_value_created_at,
  ov.updated_at as option_value_updated_at,
  ot.created_at as option_type_created_at,
  ot.updated_at as option_type_updated_at

from {{ source('shoppy_aurora', 'raw_spree_option_values') }} ov
inner join {{ source('shoppy_aurora', 'raw_spree_option_types') }} ot
  on ot.id = ov.option_type_id
where ov.id is not null 
  and ot.id is not null