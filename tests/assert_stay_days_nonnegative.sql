-- Stay length can never be negative for completed stays.
-- (Outcomes recorded before their intake are data-entry errors and are
-- excluded upstream; this test guarantees they never reach the mart.)
select
    animal_key,
    intake_month,
    outcome_type,
    stay_days
from {{ ref('mart_stay_analytics') }}
where stay_days < 0
