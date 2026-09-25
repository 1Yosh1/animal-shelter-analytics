-- Intake events fact table.
select
    lower(animal_id) as animal_key,
    animal_id,
    intake_timestamp,
    intake_date,
    intake_month,
    intake_type,
    intake_condition,
    animal_type,
    sex_upon_intake,
    age_upon_intake_years,
    found_location_raw,
    breed,
    color
from {{ ref('stg_intakes') }}
