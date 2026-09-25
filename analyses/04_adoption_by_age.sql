-- Q4: Does age at intake predict adoption odds?
-- Younger animals get adopted; the question is by how much, and where the cliff is.
with banded as (

    select
        case
            when age_upon_intake_years < 0.5 then '1. <6 months'
            when age_upon_intake_years < 1 then '2. 6-12 months'
            when age_upon_intake_years < 3 then '3. 1-3 years'
            when age_upon_intake_years < 7 then '4. 3-7 years'
            else '5. 7+ years'
        end as age_band,
        animal_type,
        outcome_category
    from {{ ref('mart_stay_analytics') }}
    where animal_type in ('Dog', 'Cat')
      and age_upon_intake_years is not null

)

select
    age_band,
    animal_type,
    count(*) as stays,
    round(100.0 * count(*) filter (where outcome_category = 'positive') / count(*), 1) as positive_pct
from banded
group by 1, 2
order by animal_type, age_band
