select
    case
        when age_upon_intake_years < 0.5 then '<6 mo'
        when age_upon_intake_years < 1 then '6-12 mo'
        when age_upon_intake_years < 3 then '1-3 yr'
        when age_upon_intake_years < 7 then '3-7 yr'
        else '7+ yr'
    end as age_band,
    animal_type,
    round(100.0 * count(*) filter (where outcome_category = 'positive') / count(*), 1) as positive_pct,
    count(*) as stays
from mart_stay_analytics
where animal_type in ('Dog', 'Cat')
  and age_upon_intake_years is not null
group by 1, 2
order by animal_type desc, age_band
