-- Staged intakes: one row per intake event, typed and cleaned.
-- Raw quirks handled here:
--   * US-format timestamps ("10/01/2013 07:51:00 AM")
--   * age strings like "2 years", "3 months", "8 weeks", "-1 years"
with source as (

    select * from {{ source('raw', 'intakes') }}

),

parsed as (

    select
        "Animal ID" as animal_id,
        nullif(trim("Name"), '') as name,
        coalesce(
            try_strptime("DateTime", '%m/%d/%Y %I:%M:%S %p'),
            try_cast("DateTime" as timestamp)
        ) as intake_timestamp,
        nullif(trim("Found Location"), '') as found_location_raw,
        nullif(trim("Intake Type"), '') as intake_type,
        nullif(trim("Intake Condition"), '') as intake_condition,
        nullif(trim("Animal Type"), '') as animal_type,
        nullif(trim("Sex upon Intake"), '') as sex_upon_intake,
        nullif(trim("Age upon Intake"), '') as age_upon_intake_raw,
        nullif(trim("Breed"), '') as breed,
        nullif(trim("Color"), '') as color
    from source

),

aged as (

    select
        *,
        case
            when age_upon_intake_raw is null then null
            when regexp_matches(age_upon_intake_raw, 'year') then
                try_cast(regexp_extract(age_upon_intake_raw, '(-?\d+)', 1) as int) * 365
            when regexp_matches(age_upon_intake_raw, 'month') then
                try_cast(regexp_extract(age_upon_intake_raw, '(-?\d+)', 1) as int) * 30
            when regexp_matches(age_upon_intake_raw, 'week') then
                try_cast(regexp_extract(age_upon_intake_raw, '(-?\d+)', 1) as int) * 7
            when regexp_matches(age_upon_intake_raw, 'day') then
                try_cast(regexp_extract(age_upon_intake_raw, '(-?\d+)', 1) as int)
            else null
        end as age_upon_intake_days
    from parsed

)

select
    lower(animal_id) as animal_key,
    animal_id,
    name,
    intake_timestamp,
    date_trunc('day', intake_timestamp) as intake_date,
    date_trunc('month', intake_timestamp) as intake_month,
    found_location_raw,
    intake_type,
    intake_condition,
    animal_type,
    sex_upon_intake,
    age_upon_intake_raw,
    age_upon_intake_days,
    round(age_upon_intake_days / 365.25, 3) as age_upon_intake_years,
    breed,
    color
from aged
