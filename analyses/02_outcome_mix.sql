-- Q2: What share of completed stays end in adoption / transfer / euthanasia,
-- per species? The species differences are the shelter's core operational fact.
select
    animal_type,
    count(*) as completed_stays,
    round(100.0 * count(*) filter (where outcome_category = 'positive') / count(*), 1) as positive_pct,
    round(100.0 * count(*) filter (where outcome_category = 'transfer') / count(*), 1) as transfer_pct,
    round(100.0 * count(*) filter (where outcome_category = 'negative') / count(*), 1) as negative_pct
from {{ ref('mart_stay_analytics') }}
where animal_type in ('Dog', 'Cat')
group by 1
order by completed_stays desc
