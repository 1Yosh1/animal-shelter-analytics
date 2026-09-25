select
    animal_type,
    outcome_category,
    round(100.0 * count(*) / sum(count(*)) over (partition by animal_type), 1) as pct
from mart_stay_analytics
where animal_type in ('Dog', 'Cat')
  and outcome_category in ('positive', 'transfer', 'negative')
group by 1, 2
