-- Q5: Which breeds flow through the shelter in the largest volume, and how do
-- their stay lengths and adoption odds compare? (Operational planning signal.)
select
    breed,
    count(*) as stays,
    round(median(stay_days), 1) as median_stay_days,
    round(100.0 * count(*) filter (where outcome_category = 'positive') / count(*), 1) as positive_pct
from {{ ref('mart_stay_analytics') }}
where animal_type = 'Dog'
group by 1
having count(*) >= 500
order by stays desc
limit 12
