-- Q1: How do intake and outcome volumes move together over time?
-- Tells us whether the shelter is structurally overloaded or seasonally stressed.
with monthly_intakes as (

    select intake_month as month, count(*) as intakes
    from {{ ref('stg_intakes') }}
    group by 1

),

monthly_outcomes as (

    select outcome_month as month, count(*) as outcomes
    from {{ ref('stg_outcomes') }}
    group by 1

)

select
    i.month,
    i.intakes,
    coalesce(o.outcomes, 0) as outcomes,
    i.intakes - coalesce(o.outcomes, 0) as net_inflow
from monthly_intakes i
left join monthly_outcomes o on i.month = o.month
order by i.month
