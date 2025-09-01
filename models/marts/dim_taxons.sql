{{ config(materialized='table') }}

with taxon_base as (
  select
    id,
    name,
    permalink,
    parent_id,
    position
  from {{ source('shoppy_aurora', 'raw_spree_taxons') }}
),

-- Loop through parent_id relationships to find all ancestor levels
taxon_hierarchy as (
  select
    t0.id,
    t0.name,
    t0.permalink,
    t0.parent_id,
    t0.position,
    
    -- Level 1 (greatest parent - where parent_id is null)
    coalesce(t7.name, t6.name, t5.name, t4.name, t3.name, t2.name, t1.name, t0.name) as cat_level_1,
    coalesce(t7.id, t6.id, t5.id, t4.id, t3.id, t2.id, t1.id, t0.id) as cat_level_1_id,
    
    -- Level 2
    case 
      when t7.id is not null then t6.name
      when t6.id is not null then t5.name
      when t5.id is not null then t4.name
      when t4.id is not null then t3.name
      when t3.id is not null then t2.name
      when t2.id is not null then t1.name
      when t1.id is not null then t0.name
    end as cat_level_2,
    case 
      when t7.id is not null then t6.id
      when t6.id is not null then t5.id
      when t5.id is not null then t4.id
      when t4.id is not null then t3.id
      when t3.id is not null then t2.id
      when t2.id is not null then t1.id
      when t1.id is not null then t0.id
    end as cat_level_2_id,
    
    -- Level 3
    case 
      when t7.id is not null then t5.name
      when t6.id is not null then t4.name
      when t5.id is not null then t3.name
      when t4.id is not null then t2.name
      when t3.id is not null then t1.name
      when t2.id is not null then t0.name
    end as cat_level_3,
    case 
      when t7.id is not null then t5.id
      when t6.id is not null then t4.id
      when t5.id is not null then t3.id
      when t4.id is not null then t2.id
      when t3.id is not null then t1.id
      when t2.id is not null then t0.id
    end as cat_level_3_id,
    
    -- Level 4
    case 
      when t7.id is not null then t4.name
      when t6.id is not null then t3.name
      when t5.id is not null then t2.name
      when t4.id is not null then t1.name
      when t3.id is not null then t0.name
    end as cat_level_4,
    case 
      when t7.id is not null then t4.id
      when t6.id is not null then t3.id
      when t5.id is not null then t2.id
      when t4.id is not null then t1.id
      when t3.id is not null then t0.id
    end as cat_level_4_id,
    
    -- Level 5
    case 
      when t7.id is not null then t3.name
      when t6.id is not null then t2.name
      when t5.id is not null then t1.name
      when t4.id is not null then t0.name
    end as cat_level_5,
    case 
      when t7.id is not null then t3.id
      when t6.id is not null then t2.id
      when t5.id is not null then t1.id
      when t4.id is not null then t0.id
    end as cat_level_5_id,
    
    -- Level 6
    case 
      when t7.id is not null then t2.name
      when t6.id is not null then t1.name
      when t5.id is not null then t0.name
    end as cat_level_6,
    case 
      when t7.id is not null then t2.id
      when t6.id is not null then t1.id
      when t5.id is not null then t0.id
    end as cat_level_6_id,
    
    -- Level 7
    case 
      when t7.id is not null then t1.name
      when t6.id is not null then t0.name
    end as cat_level_7,
    case 
      when t7.id is not null then t1.id
      when t6.id is not null then t0.id
    end as cat_level_7_id,
    
    -- Level 8
    case 
      when t7.id is not null then t0.name
    end as cat_level_8,
    case 
      when t7.id is not null then t0.id
    end as cat_level_8_id,
    
    -- Calculate hierarchy level (how deep from root)
    case
      when t7.id is not null then 8
      when t6.id is not null then 7
      when t5.id is not null then 6
      when t4.id is not null then 5
      when t3.id is not null then 4
      when t2.id is not null then 3
      when t1.id is not null then 2
      else 1
    end as hierarchy_level
    
  from taxon_base t0
  left join taxon_base t1 on t0.parent_id = t1.id
  left join taxon_base t2 on t1.parent_id = t2.id
  left join taxon_base t3 on t2.parent_id = t3.id
  left join taxon_base t4 on t3.parent_id = t4.id
  left join taxon_base t5 on t4.parent_id = t5.id
  left join taxon_base t6 on t5.parent_id = t6.id
  left join taxon_base t7 on t6.parent_id = t7.id
)

select
  -- keys
  {{ dbt_utils.generate_surrogate_key(['id']) }} as taxon_sk,
  id as taxon_nk,
  id as taxon_id,
  
  -- taxon attributes
  name as taxon_name,
  permalink as taxon_permalink,
  parent_id,
  position,
  hierarchy_level,
  
  -- flattened hierarchy levels (categories 1-8)
  cat_level_1,
  cat_level_2,
  cat_level_3,
  cat_level_4,
  cat_level_5,
  cat_level_6,
  cat_level_7,
  cat_level_8,
  
  -- hierarchy level IDs
  cat_level_1_id,
  cat_level_2_id,
  cat_level_3_id,
  cat_level_4_id,
  cat_level_5_id,
  cat_level_6_id,
  cat_level_7_id,
  cat_level_8_id,
  
  -- flags
  case when parent_id is null or parent_id = 0 then true else false end as is_root,
  case when id not in (select distinct parent_id from {{ source('shoppy_aurora', 'raw_spree_taxons') }} where parent_id is not null) then true else false end as is_leaf
  
from taxon_hierarchy