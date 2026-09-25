-- Calendar dimension covering the shelter's operating history.
with dates as (

    select distinct cast(intake_date as date) as date_day
    from {{ ref('stg_intakes') }}
    where intake_date is not null

    union

    select distinct cast(outcome_date as date) as date_day
    from {{ ref('stg_outcomes') }}
    where outcome_date is not null

)

select
    date_day,
    extract(year from date_day) as year,
    extract(month from date_day) as month,
    strftime(date_day, '%Y-%m') as year_month,
    extract(dow from date_day) as day_of_week,
    strftime(date_day, '%A') as day_name
from dates
