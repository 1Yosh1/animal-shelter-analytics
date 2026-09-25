select
    breed,
    count(*) as stays,
    round(median(stay_days), 1) as median_stay_days,
    round(count(*) filter (where outcome_category = 'positive') / count(*), 3) as positive_rate
from mart_stay_analytics
where animal_type = 'Dog'
group by 1
having count(*) >= 500
order by stays desc
