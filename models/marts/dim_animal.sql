-- One row per animal seen in the shelter system.
with stays as (

    select * from {{ ref('int_animal_stays') }}

)

select
    animal_key,
    any_value(animal_id) as animal_id,
    any_value(name) as name,
    any_value(animal_type) as animal_type,
    any_value(breed) as breed,
    any_value(color) as color,
    min(intake_timestamp) as first_intake_at,
    max(intake_timestamp) as last_intake_at,
    count(*) as total_intakes,
    count(distinct date_trunc('year', intake_timestamp)) as years_active
from stays
group by 1
