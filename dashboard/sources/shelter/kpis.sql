-- One-row KPI snapshot consumed by the BigValue tiles on the home page.
select
    (select count(*) from fct_intakes) as intake_events,
    (select count(*) from dim_animal) as animals,
    (select round(100.0 * count(*) filter (where outcome_category = 'positive') / count(*), 1) / 100
     from mart_stay_analytics) as positive_rate,
    (select round(median(stay_days), 1)
     from mart_stay_analytics) as median_stay_days
