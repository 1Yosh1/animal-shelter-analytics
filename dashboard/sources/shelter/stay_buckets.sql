select
    animal_type,
    stay_length_bucket,
    count(*) as stays
from mart_stay_analytics
where animal_type in ('Dog', 'Cat')
group by 1, 2
