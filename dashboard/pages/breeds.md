---
title: Breeds
description: Which dogs flow through the shelter, and how they fare
---

# Dog breeds: volume vs outcomes

```sql breeds
select * from shelter.breeds
```

<BarChart
    data={breeds}
    x=breed
    y=stays
    swapXY=true
    yAxisTitle="Completed stays (2013–2025)"
/>

Pit Bull Mix is the **highest-volume breed** (10,000+ stays) yet places at
**75% positive** — better than several "popular" breeds. Volume is not the
problem; the narrative around the breed is.

<DataTable data={breeds} search=true />

## Where the long stays are

```sql long_stays
select * from shelter.long_stays
```

<BarChart
    data={long_stays}
    x=breed
    y=pct_over_30d
    swapXY=true
    yAxisTitle="% of stays exceeding 30 days"
/>
