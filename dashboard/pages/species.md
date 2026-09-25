---
title: Species
description: Dogs and cats move through the shelter very differently
---

# Species: the biggest operational fact

```sql mix
select * from shelter.outcome_mix_by_species
```

<BarChart
    data={mix}
    x=animal_type
    y=pct
    series=outcome_category
    type=stacked
    yAxisTitle="% of completed stays"
/>

**75% of dog stays** end in adoption or return-to-owner, vs **56% of cats** —
cats are instead transferred to partner organizations at nearly double the
dog rate.

## The age cliff is cat-specific

```sql age_bands
select * from shelter.age_bands
```

<BarChart
    data={age_bands}
    x=age_band
    y=positive_pct
    series=animal_type
    yAxisTitle="% positive outcome"
/>

Dogs hold 70–79% across **every** age band. Cats collapse to **48%** in the
6–12 month window — adolescent cats are the hardest population to place.

## Cats wait longer at every point of the distribution

```sql stay_buckets
select * from shelter.stay_buckets
```

<BarChart
    data={stay_buckets}
    x=stay_length_bucket
    y=stays
    series=animal_type
    yAxisTitle="Completed stays"
/>
