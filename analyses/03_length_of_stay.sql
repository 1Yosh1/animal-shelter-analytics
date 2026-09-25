-- Q3: How long do animals stay, and which species waits longest?
with los as (

    select
        animal_type,
        stay_days,
        stay_length_bucket
    from {{ ref('mart_stay_analytics') }}
    where animal_type in ('Dog', 'Cat')

)

select
    animal_type,
    count(*) as completed_stays,
    round(median(stay_days), 1) as median_stay_days,
    round(avg(stay_days), 1) as mean_stay_days,
    max(stay_days) as max_stay_days,
    round(100.0 * count(*) filter (where stay_days > 30) / count(*), 1) as pct_over_30_days
from los
group by 1
order by median_stay_days desc
