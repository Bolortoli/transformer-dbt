{{
  config(
    materialized='table',
    partition_by={'field': 'created_at', 'data_type': 'datetime'},
    cluster_by=['store_id','vendor_id']
  )
}}

with src as (
  select
    id as order_id,
    number as order_number,
    email,
    state as order_state,
    channel,
    user_id,
    store_id,
    vendor_id,
    total as order_total,
    item_total,
    item_count,
    promo_total,
    payment_total,
    shipment_total,
    included_tax_total,
    additional_tax_total,
    payment_state,
    shipment_state,
    created_at,
    updated_at,
    completed_at,
    canceled_at,
    _airbyte_extracted_at as extracted_at
  from {{ source('shoppy_aurora','raw_spree_orders') }}
)

select * from src


