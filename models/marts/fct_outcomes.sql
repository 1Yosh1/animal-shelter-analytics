-- Outcome events fact table.
select
    lower(animal_id) as animal_key,
    animal_id,
    outcome_timestamp,
    outcome_date,
    outcome_month,
    outcome_type,
    outcome_subtype,
    animal_type,
    sex_upon_outcome,
    age_upon_outcome_years
from {{ ref('stg_outcomes') }}
