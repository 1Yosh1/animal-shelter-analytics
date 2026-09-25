-- Each intake paired with the next outcome for the same animal.
-- This is the heart of the warehouse: converts event streams into "stays"
-- that can be analyzed for length-of-stay and outcomes.
--
-- Stay statuses:
--   completed          -> an outcome at/after the intake was found
--   data_quality_issue -> the animal's only outcome(s) are dated BEFORE the
--                         intake (portal data-entry error); never joins to
--                         the stay analytics mart
--   open_stay          -> no outcome recorded (animal still in care, or the
--                         intake/outcome streams are out of sync)
with intakes as (

    select * from {{ ref('stg_intakes') }}

),

outcomes as (

    select * from {{ ref('stg_outcomes') }}

),

-- The portal contains exact duplicate outcome rows (same animal, same
-- timestamp). Deduplicate so downstream joins never multiply stays.
outcomes_dedup as (

    select *
    from outcomes
    qualify row_number() over (
        partition by animal_key, outcome_timestamp
        order by outcome_type nulls last
    ) = 1

),

next_outcome as (

    -- earliest outcome at or after each intake
    select
        i.animal_key,
        i.intake_timestamp,
        o.outcome_timestamp as next_outcome_ts
    from intakes i
    join outcomes_dedup o
        on i.animal_key = o.animal_key
        and o.outcome_timestamp >= i.intake_timestamp
    qualify row_number() over (
        partition by i.animal_key, i.intake_timestamp
        order by o.outcome_timestamp asc
    ) = 1

),

prior_outcome as (

    -- latest outcome strictly before each intake (data-entry errors)
    select
        i.animal_key,
        i.intake_timestamp,
        max(o.outcome_timestamp) as prior_outcome_ts
    from intakes i
    join outcomes_dedup o
        on i.animal_key = o.animal_key
        and o.outcome_timestamp < i.intake_timestamp
    group by 1, 2

),

joined as (

    select
        i.*,
        n.next_outcome_ts,
        p.prior_outcome_ts
    from intakes i
    left join next_outcome n
        on i.animal_key = n.animal_key
        and i.intake_timestamp = n.intake_timestamp
    left join prior_outcome p
        on i.animal_key = p.animal_key
        and i.intake_timestamp = p.intake_timestamp

),

paired as (

    select
        j.animal_key,
        j.animal_id,
        j.name,
        j.animal_type,
        j.breed,
        j.color,
        j.intake_type,
        j.intake_condition,
        j.sex_upon_intake,
        j.intake_timestamp,
        j.intake_month,
        j.age_upon_intake_years,
        j.next_outcome_ts as outcome_timestamp,
        o.outcome_type,
        o.outcome_subtype,
        o.sex_upon_outcome,
        o.date_of_birth,
        date_diff('day', date_trunc('day', j.intake_timestamp),
                  date_trunc('day', j.next_outcome_ts)) as stay_days,
        round(
            date_diff('day', date_trunc('day', j.intake_timestamp),
                      date_trunc('day', j.next_outcome_ts)) / 7.0, 2
        ) as stay_weeks
    from joined j
    left join outcomes_dedup o
        on j.animal_key = o.animal_key
        and j.next_outcome_ts = o.outcome_timestamp
    where next_outcome_ts is not null

    union all

    -- intakes whose only outcome(s) precede them: keep visible, flagged
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
        intake_timestamp,
        intake_month,
        age_upon_intake_years,
        prior_outcome_ts as outcome_timestamp,
        null as outcome_type,
        null as outcome_subtype,
        null as sex_upon_outcome,
        null as date_of_birth,
        null as stay_days,
        null as stay_weeks
    from joined
    where next_outcome_ts is null
      and prior_outcome_ts is not null

),

classified as (

    select
        *,
        case
            when outcome_timestamp is null then 'open_stay'
            when stay_days < 0 then 'data_quality_issue'
            when outcome_type is null and outcome_timestamp is not null then 'data_quality_issue'
            else 'completed'
        end as stay_status
    from paired

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
    intake_timestamp,
    intake_month,
    age_upon_intake_years,
    outcome_timestamp,
    cast(outcome_timestamp as date) as outcome_date,
    outcome_type,
    outcome_subtype,
    sex_upon_outcome,
    date_of_birth,
    stay_days,
    stay_weeks,
    stay_status
from classified
