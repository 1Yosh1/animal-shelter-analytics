-- Staged outcomes: one row per outcome event, typed and cleaned.
-- Raw quirks handled here:
--   * ISO timestamps with offsets ("2013-12-02T00:00:00-05:00") alongside
--     US-format strings
--   * "Date of Birth" already ISO; sometimes missing entirely
--   * duplicate rows (same animal, same outcome, twice)
with source as (

    select * from {{ source('raw', 'outcomes') }}

),

parsed as (

    select
        "Animal ID" as animal_id,
        nullif(trim("Date of Birth"), '') as date_of_birth_raw,
        nullif(trim("Name"), '') as name,
        coalesce(
            try_strptime("DateTime", '%m/%d/%Y %I:%M:%S %p'),
            try_cast("DateTime" as timestamp)
        ) as outcome_timestamp,
        nullif(trim("Outcome Type"), '') as outcome_type,
        nullif(trim("Outcome Subtype"), '') as outcome_subtype,
        nullif(trim("Animal Type"), '') as animal_type,
        nullif(trim("Sex upon Outcome"), '') as sex_upon_outcome,
        nullif(trim("Age upon Outcome"), '') as age_upon_outcome_raw,
        nullif(trim("Breed"), '') as breed,
        nullif(trim("Color"), '') as color
    from source

),

aged as (

    select
        *,
        case
            when age_upon_outcome_raw is null then null
            when regexp_matches(age_upon_outcome_raw, 'year') then
                try_cast(regexp_extract(age_upon_outcome_raw, '(-?\d+)', 1) as int) * 365
            when regexp_matches(age_upon_outcome_raw, 'month') then
                try_cast(regexp_extract(age_upon_outcome_raw, '(-?\d+)', 1) as int) * 30
            when regexp_matches(age_upon_outcome_raw, 'week') then
                try_cast(regexp_extract(age_upon_outcome_raw, '(-?\d+)', 1) as int) * 7
            when regexp_matches(age_upon_outcome_raw, 'day') then
                try_cast(regexp_extract(age_upon_outcome_raw, '(-?\d+)', 1) as int)
            else null
        end as age_upon_outcome_days
    from parsed

)

select
    lower(animal_id) as animal_key,
    animal_id,
    try_cast(date_of_birth_raw as date) as date_of_birth,
    name,
    outcome_timestamp,
    date_trunc('day', outcome_timestamp) as outcome_date,
    date_trunc('month', outcome_timestamp) as outcome_month,
    outcome_type,
    outcome_subtype,
    animal_type,
    sex_upon_outcome,
    age_upon_outcome_raw,
    age_upon_outcome_days,
    round(age_upon_outcome_days / 365.25, 3) as age_upon_outcome_years
from aged
