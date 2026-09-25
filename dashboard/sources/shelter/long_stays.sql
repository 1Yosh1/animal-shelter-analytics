select
    breed,
    round(100.0 * count(*) filter (where stay_days > 30) / count(*), 1) as pct_over_30d
from mart_stay_analytics
where animal_type = 'Dog'
group by 1
having count(*) >= 500
order by pct_over_30d desc
limit 15
