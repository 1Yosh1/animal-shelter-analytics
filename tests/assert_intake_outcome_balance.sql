-- Reconciliation: staged intakes must match the intake fact table 1:1.
-- Catches accidental row loss/multiplication anywhere in the pipeline.
select
    'intakes' as check_name,
    (select count(*) from {{ ref('stg_intakes') }}) as staged_count,
    (select count(*) from {{ ref('fct_intakes') }}) as fact_count
where (select count(*) from {{ ref('stg_intakes') }})
      != (select count(*) from {{ ref('fct_intakes') }})
