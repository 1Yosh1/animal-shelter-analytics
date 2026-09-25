-- Every completed stay must land in a known outcome category.
-- Catches new/renamed outcome types appearing in refreshed portal data.
-- (Vocabulary verified against the 2025-09 portal snapshot: see mart_stay_analytics
-- for the mapping into outcome_category.)
select
    distinct outcome_type
from {{ ref('int_animal_stays') }}
where outcome_type is not null
  and outcome_type not in (
      'Adoption', 'Return to Owner', 'Rto-Adopt', 'Transfer', 'Relocate',
      'Euthanasia', 'Died', 'Disposal', 'Missing', 'Lost', 'Stolen'
  )
