select
    intake_type,
    count(*) as n
from fct_intakes
group by 1
order by n desc
