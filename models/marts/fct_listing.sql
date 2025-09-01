{{
  config(
    materialized='incremental',
    unique_key=['listing_id', 'updated_at'],
    cluster_by=['listing_id', 'product_sk'],
    partition_by={
      'field': 'updated_at',
      'data_type': 'timestamp',
      'granularity': 'day'
    },
    on_schema_change='append_new_columns'
  )
}}

-- Optimized incremental version of fct_listing with performance improvements:
-- 1. Incremental materialization for faster processing
-- 2. Proper JOINs instead of correlated subqueries
-- 3. Daily partitioning for better query performance
-- 4. Reduced complexity with essential data only

-- Base listing data with product relationships
with base_listings as (
  select
    l.id as listing_id,
    l.product_id,
    l.website_id,
    l.approved,
    l.published,
    l.created_at,
    l.updated_at,
    p.vendor_id,
    p.store_id
  from {{ source('shoppy_aurora', 'raw_shoppy_listings') }} l
  left join {{ source('shoppy_aurora', 'raw_spree_products') }} p
    on p.id = l.product_id
    and p.deleted_at is null
  {% if is_incremental() %}
    where l.updated_at > (select max(updated_at) from {{ this }})
  {% endif %}
),

-- Get previous records for change detection
previous_listings as (
  {% if is_incremental() %}
  select
    abs(farm_fingerprint(cast(listing_id as string))) as listing_sk,
    stock_quantity as prev_stock_quantity,
    price as prev_price,
    approved as prev_approved,
    published as prev_published,
    row_number() over (partition by abs(farm_fingerprint(cast(listing_id as string))) order by updated_at desc) as rn
  from {{ this }}
  {% else %}
  select
    cast(null as int64) as listing_sk,
    cast(null as int64) as prev_stock_quantity,
    cast(null as numeric) as prev_price,
    cast(null as boolean) as prev_approved,
    cast(null as boolean) as prev_published,
    1 as rn
  limit 0
  {% endif %}
),

latest_previous_listings as (
  select * from previous_listings where rn = 1
),

-- Get variant data (first variant per product)
variants_agg as (
  select
    product_id,
    array_agg(v order by v.id limit 1)[offset(0)].id as variant_id
  from {{ source('shoppy_aurora', 'raw_spree_variants') }} v
  where v.deleted_at is null
  group by product_id
),

-- Get stock data (aggregated)
stock_agg as (
  select
    v.product_id,
    sum(si.count_on_hand) as stock_quantity,
    array_agg(si.stock_location_id ignore nulls limit 1)[safe_offset(0)] as stock_location_id
  from {{ source('shoppy_aurora', 'raw_spree_stock_items') }} si
  join {{ source('shoppy_aurora', 'raw_spree_variants') }} v
    on v.id = si.variant_id
    and v.deleted_at is null
    and si.deleted_at is null
  group by v.product_id
),

-- Get price data (first price per product)
price_agg as (
  select
    v.product_id,
    array_agg(p order by p.id limit 1)[offset(0)].amount as price,
    array_agg(p order by p.id limit 1)[offset(0)].currency as currency
  from {{ source('shoppy_aurora', 'raw_spree_prices') }} p
  join {{ source('shoppy_aurora', 'raw_spree_variants') }} v
    on v.id = p.variant_id
    and v.deleted_at is null
  group by v.product_id
),

-- Get taxon data (primary taxon per listing)
taxon_agg as (
  select
    lt.listing_id,
    array_agg(t.id order by t.parent_id desc nulls last, t.id limit 1)[offset(0)] as primary_taxon_id
  from {{ source('shoppy_aurora', 'raw_shoppy_listings_taxons') }} lt
  join {{ source('shoppy_aurora', 'raw_spree_taxons') }} t 
    on t.id = lt.taxon_id
  group by lt.listing_id
),

-- Change detection logic
change_detection as (
  select
    bl.*,
    cast(format_date('%Y%m%d', date(bl.created_at)) as int64) as created_date_nk,
    
    -- Aggregated metrics
    va.variant_id,
    coalesce(sa.stock_quantity, 0) as stock_quantity,
    sa.stock_location_id,
    coalesce(cast(pa.price as numeric), 0) as price,
    pa.currency,
    ta.primary_taxon_id,
    
    -- Previous values for comparison
    coalesce(lpl.prev_stock_quantity, 0) as prev_stock_quantity,
    coalesce(lpl.prev_price, 0) as prev_price,
    coalesce(lpl.prev_approved, false) as prev_approved,
    coalesce(lpl.prev_published, false) as prev_published,
    
    -- Determine event type and action based on changes
    case
      -- Stock changes
      when coalesce(sa.stock_quantity, 0) > coalesce(lpl.prev_stock_quantity, 0) then 'stock'
      when coalesce(sa.stock_quantity, 0) < coalesce(lpl.prev_stock_quantity, 0) then 'stock'
      -- Price changes  
      when coalesce(cast(pa.price as numeric), 0) != coalesce(lpl.prev_price, 0) then 'price'
      -- Listing status changes
      when (bl.approved != coalesce(lpl.prev_approved, false)) or (bl.published != coalesce(lpl.prev_published, false)) then 'listing'
      -- Default to listing event for new records
      else 'listing'
    end as event_type,
    
    case
      -- Stock actions
      when coalesce(sa.stock_quantity, 0) > coalesce(lpl.prev_stock_quantity, 0) then 'update-inc'
      when coalesce(sa.stock_quantity, 0) < coalesce(lpl.prev_stock_quantity, 0) then 'update-dec'
      -- Price actions
      when coalesce(cast(pa.price as numeric), 0) > coalesce(lpl.prev_price, 0) then 'update-inc'
      when coalesce(cast(pa.price as numeric), 0) < coalesce(lpl.prev_price, 0) then 'update-dec'
      -- Listing status actions
      when bl.approved = true and bl.published = true and not (coalesce(lpl.prev_approved, false) and coalesce(lpl.prev_published, false)) then 'published'
      when (bl.approved = false or bl.published = false) and (coalesce(lpl.prev_approved, false) and coalesce(lpl.prev_published, false)) then 'unpublished'
      -- Default to create for new records or published for active listings
      when lpl.listing_sk is null then 'create'
      when bl.approved = true and bl.published = true then 'published'
      else 'unpublished'
    end as event_action
    
  from base_listings bl
  left join latest_previous_listings lpl on lpl.listing_sk = abs(farm_fingerprint(cast(bl.listing_id as string)))
  left join variants_agg va on va.product_id = bl.product_id
  left join stock_agg sa on sa.product_id = bl.product_id
  left join price_agg pa on pa.product_id = bl.product_id
  left join taxon_agg ta on ta.listing_id = bl.listing_id
),

-- Final assembly with dimension lookups
final_with_dimensions as (
  select
    cd.*,
    
    -- Essential dimension keys only
    dp.product_sk,
    dv.variant_sk,
    coalesce(ds.store_sk, 'UNKNOWN') as store_sk,
    coalesce(dven.vendor_sk, 'UNKNOWN') as vendor_sk,
    coalesce(dw.website_sk, 'UNKNOWN') as website_sk,
    coalesce(dd.date_sk, 'UNKNOWN') as created_date_sk,
    coalesce(dsl.stock_location_sk, 'UNKNOWN') as stock_location_sk,
    coalesce(dt.taxon_sk, 'UNKNOWN') as taxon_sk,
    coalesce(cast(dle.id as string), 'UNKNOWN') as listing_event_sk
    
  from change_detection cd
  -- Dimension table joins
  left join {{ ref('dim_product') }} dp on dp.product_nk = cd.product_id
  left join {{ ref('dim_variants') }} dv on dv.variant_nk = cd.variant_id
  left join {{ ref('dim_stores') }} ds on ds.store_nk = cd.store_id
  left join {{ ref('dim_vendors') }} dven on dven.vendor_nk = cd.vendor_id
  left join {{ ref('dim_websites') }} dw on dw.website_nk = cd.website_id
  left join {{ ref('dim_dates') }} dd on dd.date_nk = cd.created_date_nk
  left join {{ ref('dim_stock_locations') }} dsl on dsl.stock_location_nk = cd.stock_location_id
  left join {{ ref('dim_taxons') }} dt on dt.taxon_nk = cd.primary_taxon_id
  left join {{ ref('dim_listing_events') }} dle on 
    dle.event_type = cd.event_type and 
    dle.action = cd.event_action
)

select
  -- Listing identifiers
  listing_id,
  abs(farm_fingerprint(cast(listing_id as string))) as listing_sk,
  
  -- Essential dimension foreign keys
  product_sk,
  variant_sk,
  store_sk,
  vendor_sk,
  website_sk,
  created_date_sk,
  stock_location_sk,
  taxon_sk,
  listing_event_sk,
  
  -- Natural keys for reference
  product_id as product_nk,
  variant_id as variant_nk,
  store_id as store_nk,
  vendor_id as vendor_nk,
  website_id as website_nk,
  primary_taxon_id as taxon_nk,
  stock_location_id as stock_location_nk,
  created_date_nk,
  
  -- Metrics
  stock_quantity,
  coalesce(cast(price as numeric), 0) as price,
  currency,
  
  -- Flags
  approved,
  published,
  case when approved and published then true else false end as is_active,
  case when stock_quantity > 0 then true else false end as has_stock,
  
  -- Dates
  created_at,
  updated_at,
  
  -- Metadata
  current_timestamp() as dw_created_at,
  current_timestamp() as dw_updated_at

from final_with_dimensions