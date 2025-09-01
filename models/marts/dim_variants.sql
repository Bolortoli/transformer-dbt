  {{ config(materialized='table') }}

with base as (
  select * from {{ source('shoppy_aurora', 'raw_spree_variants') }}
), ranked as (
  select
    b.*,
    row_number() over (
      partition by b.id
      order by 
        case when b.deleted_at is null then 0 else 1 end asc,
        b.updated_at desc,
        b._airbyte_extracted_at desc
    ) as rn
  from base b
)
select
  -- keys
  {{ dbt_utils.generate_surrogate_key(['id']) }} as variant_sk,
  id as variant_nk,

  -- natural and attributes
  id,
  sku,
  coalesce(weight, 0) as weight,
  coalesce(height, 0) as height,
  coalesce(width, 0) as width,
  coalesce(depth, 0) as depth,
  barcode
from ranked
where rn = 1

