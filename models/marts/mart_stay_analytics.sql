-- Analysis-ready stay table: one row per shelter stay with a simplified
-- outcome category used across the insight analyses.
with stays as (

    select * from {{ ref('int_animal_stays') }}

),

categorized as (

    select
        *,
        case
            when outcome_type is null then 'unknown'
            when outcome_type in ('Adoption', 'Return to Owner', 'Rto-Adopt') then 'positive'
            when outcome_type in ('Transfer', 'Relocate') then 'transfer'
            when outcome_type in ('Euthanasia', 'Died', 'Disposal') then 'negative'
            when outcome_type in ('Missing', 'Lost', 'Stolen') then 'missing'
            else 'other'
        end as outcome_category,
        case
            when stay_days between 0 and 6 then '0-6 days'
            when stay_days between 7 and 13 then '1-2 weeks'
            when stay_days between 14 and 29 then '2-4 weeks'
            when stay_days between 30 and 89 then '1-3 months'
            when stay_days >= 90 then '3+ months'
            else 'open/other'
        end as stay_length_bucket
    from stays
    where stay_status = 'completed'

)

select
    animal_key,
    animal_id,
    name,
    animal_type,
    breed,
    color,
    intake_type,
    intake_condition,
    sex_upon_intake,
    intake_month,
    year(intake_month) as intake_year,
    age_upon_intake_years,
    outcome_type,
    outcome_category,
    stay_days,
    stay_length_bucket
from categorized
