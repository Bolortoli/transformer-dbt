-- This dimension table has been integrated into fct_listing.sql
-- The listing events logic is now part of the fact table directly

{{ config(
  materialized = 'table'
) }}

with event_types as (
  select 'listing' as event_type union all
  select 'order' union all
  select 'price' union all
  select 'price-sales' union all
  select 'stock' union all
  select 'erp_stock'
),
actions as (
  select 'create' as action union all
  select 'update-inc' union all
  select 'update-dec' union all
  select 'delete' union all
  select 'published' union all
  select 'unpublished'
),
events as (
  select
    et.event_type,
    a.action,
    concat(et.event_type, ':', a.action) as natural_key
  from event_types et
  cross join actions a
)

select
  abs(farm_fingerprint(natural_key)) as id,
  abs(farm_fingerprint(natural_key)) as event_id,
  event_type,
  action,
  cast(null as string) as comment
from events


