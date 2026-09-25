with i as (
    select intake_month as month, count(*) as intakes
    from fct_intakes group by 1
),
o as (
    select outcome_month as month, count(*) as outcomes
    from fct_outcomes group by 1
)
select
    coalesce(i.month, o.month) as month,
    i.intakes,
    o.outcomes
from i
full outer join o on i.month = o.month
order by 1
