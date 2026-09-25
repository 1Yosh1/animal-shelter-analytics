-- Monitoring test: rows with no recorded outcome type should stay rare.
-- The raw portal data has 46 such rows (0.03%, mostly wildlife). If a future
-- refresh pushes this above 1%, something changed upstream and we should look.
with totals as (

    select
        count(*) as total_outcomes,
        count(*) filter (where outcome_type is null) as unknown_outcomes
    from {{ ref('stg_outcomes') }}

)

select *
from totals
where unknown_outcomes > 0.01 * total_outcomes
