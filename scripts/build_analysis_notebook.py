"""Build and execute the analysis notebook from the built warehouse.

Run from the repo root after `make load` + `make build`:
    .venv/bin/python scripts/build_analysis_notebook.py
"""
from __future__ import annotations

import nbformat as nbf
from nbclient import NotebookClient

nb = nbf.v4.new_notebook()
cells = []


def md(text: str) -> None:
    cells.append(nbf.v4.new_markdown_cell(text))


def code(source: str) -> None:
    cells.append(nbf.v4.new_code_cell(source))


md(
    """# Austin Animal Shelter Analytics

An analytics warehouse built with **dbt + DuckDB** over the city of Austin's
open-data portal, answering operational questions from 347K raw intake/outcome
events (2013–2025).

**Layered architecture** (run by `dbt build`, all tested):

```
raw (portal CSVs, untouched)
  └─ staging  stg_intakes, stg_outcomes        typed, renamed, cleaned
      └─ intermediate  int_animal_stays      intakes paired with outcomes
          └─ marts  dim_animal, dim_date, fct_intakes, fct_outcomes,
                    mart_stay_analytics        analysis-ready star schema
```

Every chart below is a warehouse query. Findings are summarized at the end."""
)

code(
    """%matplotlib inline

import duckdb
import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns

sns.set_theme(style="whitegrid", palette="deep")
plt.rcParams["figure.dpi"] = 110
plt.rcParams["axes.titleweight"] = "bold"

con = duckdb.connect("warehouse/animal_shelter.duckdb", read_only=True)


def q(sql: str) -> pd.DataFrame:
    return con.execute(sql).df()


print("connected")"""
)

md("## The raw layer is faithfully messy")

code(
    """counts = q(\"\"\"
    select 'intakes' as table_name, count(*) as rows from raw.intakes
    union all
    select 'outcomes', count(*) from raw.outcomes
\"\"\")
display(counts)

# The two files even disagree on timestamp format:
q(\"\"\"
    select * from (select 'intake' as stream, "DateTime" as raw_datetime from raw.intakes limit 2) a
    union all
    select * from (select 'outcome' as stream, "DateTime" as raw_datetime from raw.outcomes limit 2) b
\"\"\")"""
)

md(
    """Raw quirks we found and handle in staging: two different datetime formats, age
strings like `"8 weeks"` / `"-1 years"`, location typos (`"Norht Ec"`), duplicate
outcome rows, and animals whose recorded outcome **precedes** their intake. The
staging layer types and cleans; the data tests guarantee it."""
)

md("## Staging: ages parsed, timestamps unified")

code(
    """age_check = q(\"\"\"
    select animal_type, age_upon_intake_years
    from stg_intakes
    where age_upon_intake_years between 0 and 20
\"\"\")
fig, ax = plt.subplots(figsize=(9, 4))
for species, color in [("Dog", "#4C72B0"), ("Cat", "#DD8452")]:
    subset = age_check.loc[age_check["animal_type"] == species, "age_upon_intake_years"]
    ax.hist(subset, bins=40, alpha=0.55, density=True, color=color, label=species)
ax.set_xlabel("Age at intake (years)")
ax.set_ylabel("Density")
ax.set_title("Age at intake, parsed from raw age strings")
ax.legend()
plt.tight_layout()
plt.show()"""
)

md(
    "## Stays: pairing intakes with outcomes\n\n"
    "The core transformation: each intake is paired with the animal's next outcome. "
    "Rows that can't logically exist (outcome before intake) are flagged, not hidden."
)

code(
    """statuses = q(\"\"\"
    select stay_status, count(*) as stays,
           round(100.0 * count(*) / sum(count(*)) over (), 2) as pct
    from int_animal_stays group by 1 order by stays desc
\"\"\")
display(statuses)"""
)

md("## Analysis 1 — Monthly flow: is the shelter getting more animals than it releases?")

code(
    """flow = q(\"\"\"
    select * from (
        select intake_month as month, count(*) as intakes
        from stg_intakes group by 1
    ) i
    full outer join (
        select outcome_month as month, count(*) as outcomes
        from stg_outcomes group by 1
    ) o using (month)
    order by month
\"\"\")
flow["net_inflow"] = flow["intakes"] - flow["outcomes"]

fig, ax = plt.subplots(figsize=(12, 4.5))
ax.plot(flow["month"], flow["intakes"], color="#4C72B0", lw=1.5, label="Intakes")
ax.plot(flow["month"], flow["outcomes"], color="#55A868", lw=1.5, label="Outcomes")
ax.fill_between(flow["month"], flow["intakes"], flow["outcomes"],
                where=flow["net_inflow"] > 0, color="#C44E52", alpha=0.25,
                label="Net inflow (pressure)")
ax.set_title("Monthly intakes vs outcomes")
ax.set_ylabel("Animals per month")
ax.legend()
plt.tight_layout()
plt.show()"""
)

md("## Analysis 2 — Outcome mix by species")

code(
    """mix = q(\"\"\"
    select * from (
        select animal_type,
               100.0 * count(*) filter (where outcome_category = 'positive') / count(*) as positive_pct,
               100.0 * count(*) filter (where outcome_category = 'transfer') / count(*) as transfer_pct,
               100.0 * count(*) filter (where outcome_category = 'negative') / count(*) as negative_pct
        from mart_stay_analytics
        where animal_type in ('Dog', 'Cat')
        group by 1
    ) order by animal_type desc
\"\"\")
fig, ax = plt.subplots(figsize=(9, 4))
bottom = pd.Series(0.0, index=mix.index)
for col, color, label in [("positive_pct", "#55A868", "Adopted / returned to owner"),
                          ("transfer_pct", "#4C72B0", "Transferred to partner orgs"),
                          ("negative_pct", "#C44E52", "Euthanized / died")]:
    ax.barh(mix["animal_type"], mix[col], left=bottom, color=color, label=label)
    bottom += mix[col]
ax.set_xlabel("% of completed stays")
ax.set_title("What happens to shelter animals, by species")
ax.legend(ncol=3, loc="upper center", bbox_to_anchor=(0.5, -0.12))
plt.tight_layout()
plt.show()
display(mix.round(1))"""
)

md("## Analysis 3 — Length of stay")

code(
    """los = q(\"\"\"
    select animal_type, stay_days
    from mart_stay_analytics
    where animal_type in ('Dog', 'Cat') and stay_days <= 60
\"\"\")
summary = q(\"\"\"
    select animal_type, round(median(stay_days), 1) as median_days,
           round(avg(stay_days), 1) as mean_days,
           round(100.0 * count(*) filter (where stay_days > 30) / count(*), 1) as pct_over_30d
    from mart_stay_analytics where animal_type in ('Dog', 'Cat')
    group by 1 order by 2 desc
\"\"\")
display(summary)

fig, ax = plt.subplots(figsize=(10, 4))
for species, color in [("Cat", "#DD8452"), ("Dog", "#4C72B0")]:
    subset = los.loc[los["animal_type"] == species, "stay_days"]
    ax.hist(subset, bins=60, alpha=0.55, density=True, color=color, label=species)
ax.axvline(30, color="black", ls="--", lw=1, label="30 days")
ax.set_xlabel("Completed stay length (days, ≤60 shown)")
ax.set_ylabel("Density")
ax.set_title("Cats wait longer than dogs at every point of the distribution")
ax.legend()
plt.tight_layout()
plt.show()"""
)

md("## Analysis 4 — Adoption rate by age band")

code(
    """age = q(\"\"\"
    select * from (
        select
            case
                when age_upon_intake_years < 0.5 then '1. <6 mo'
                when age_upon_intake_years < 1 then '2. 6-12 mo'
                when age_upon_intake_years < 3 then '3. 1-3 yr'
                when age_upon_intake_years < 7 then '4. 3-7 yr'
                else '5. 7+ yr'
            end as age_band,
            animal_type,
            100.0 * count(*) filter (where outcome_category = 'positive') / count(*) as positive_pct,
            count(*) as stays
        from mart_stay_analytics
        where animal_type in ('Dog', 'Cat') and age_upon_intake_years is not null
        group by 1, 2
    ) order by animal_type desc, age_band
\"\"\")
fig, ax = plt.subplots(figsize=(10, 4.5))
sns.barplot(data=age, x="age_band", y="positive_pct", hue="animal_type", ax=ax,
            palette=["#4C72B0", "#DD8452"])
ax.set_xlabel("Age at intake")
ax.set_ylabel("% adopted / returned to owner")
ax.set_title("Positive-outcome rate by age band")
for container in ax.containers:
    ax.bar_label(container, fmt="%.0f%%", fontsize=8)
ax.legend(title="")
plt.tight_layout()
plt.show()
display(age.round(1))"""
)

md("## Analysis 5 — Top breeds by volume (dogs, ≥500 stays)")

code(
    """breeds = q(\"\"\"
    select * from (
        select breed, count(*) as stays,
               round(median(stay_days), 1) as median_stay_days,
               100.0 * count(*) filter (where outcome_category = 'positive') / count(*) as positive_pct
        from mart_stay_analytics
        where animal_type = 'Dog'
        group by 1 having count(*) >= 500
    ) order by stays desc limit 12
\"\"\")
fig, ax = plt.subplots(figsize=(10, 5))
bar_colors = ["#C44E52" if v < 70 else ("#DD8452" if v < 76 else "#55A868")
              for v in breeds["positive_pct"]]
ax.barh(breeds["breed"][::-1], breeds["stays"][::-1], color=bar_colors[::-1])
ax.set_xlabel("Completed stays (2013-2025)")
ax.set_title("Highest-volume dog breeds — green = ≥76% positive outcome, red = <70%")
plt.tight_layout()
plt.show()
display(breeds.round(1))"""
)

md(
    """## Findings

1. **The system is balanced, not structurally overloaded.** Monthly outcomes track
   intakes closely; sustained pressure appears only in spring/summer "kitten season"
   spikes, not as a long-term deficit.
2. **Species inequality is the biggest operational fact.** 75% of dog stays end in a
   positive outcome (adoption or owner reunion) vs 56% of cats; cats are also
   transferred out at nearly double the rate and wait longer (median 7 vs 6 days,
   25.5% vs 15.8% still in care past 30 days).
3. **The age cliff is real but species-specific.** Dogs adopt at 70-79% across every
   age band. Cats show a U-shape: kittens (<6 mo, 59%) do fine, but the 6-12 month
   band collapses to 48% — adolescent cats are the hardest population to place.
4. **Volume ≠ doom.** Pit Bull Mix is the #1 breed by volume (10,026 stays) yet
   achieves a 75% positive-outcome rate, beating several "popular" breeds.
5. **The portal data needs the guardrails we built.** Duplicate outcomes, two
   datetime formats, impossible age strings, and 46 animals with no outcome at all —
   all caught by the test suite (30 dbt tests + 5 pipeline tests).

## What is tested

- **staging**: not-null keys, parsed timestamps, valid species/values
- **intermediate/marts**: grain (one row per stay), reconciliation
  (staged rows = fact rows), no negative stays, exhaustive outcome categories
- **monitoring**: unknown-outcome rate kept under 1% (today: 0.03%)
- **pipeline tests (pytest)**: duplicate outcomes never multiply stays;
  outcome-before-intake is flagged as a data-quality issue, never silently paired"""
)

out = nbf.v4.new_notebook()
out.cells = cells
out.metadata["kernelspec"] = {
    "display_name": "venv",
    "language": "python",
    "name": "python3",
}

client = NotebookClient(out, timeout=600, kernel_name="python3")
client.execute()

path = "notebooks/analysis.ipynb"
nbf.write(out, path)
print(f"Executed and wrote: {path} ({len(out.cells)} cells)")
