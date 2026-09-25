---
title: Austin Animal Shelter
description: 12 years of intakes and outcomes, from the city's open-data portal
---

# Austin Animal Shelter Operations

```sql kpis
select * from shelter.kpis
```

<BigValue
    data={kpis}
    value=intake_events
    title="Intake events" fmt=num0
/>

<BigValue
    data={kpis}
    value=animals
    title="Distinct animals" fmt=num0
/>

<BigValue
    data={kpis}
    value=positive_rate
    title="Positive outcomes" fmt=pct1
/>

<BigValue
    data={kpis}
    value=median_stay_days
    title="Median stay (days)" fmt=num1
/>

## Monthly flow: intakes vs outcomes

```sql flow
select * from shelter.flow order by month
```

<LineChart
    data={flow}
    x=month
    y={['intakes', 'outcomes']}
    yAxisTitle="Animals per month"
/>

Outcomes track intakes almost perfectly over 12 years — the shelter is
balanced, with pressure arriving seasonally (spring/summer kitten season)
rather than structurally.

## How animals arrive

```sql intake_mix
select * from shelter.intake_mix
```

<BarChart
    data={intake_mix}
    x=intake_type
    y=n
    swapXY=true
    yAxisTitle="Intake events"
/>
