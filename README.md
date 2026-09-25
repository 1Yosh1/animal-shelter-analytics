# 🐾 Austin Animal Shelter Analytics

[![CI](https://github.com/1Yosh1/animal-shelter-analytics/actions/workflows/ci.yml/badge.svg)](https://github.com/1Yosh1/animal-shelter-analytics/actions/workflows/ci.yml)
[![Dashboard](https://img.shields.io/badge/dashboard-live-2ea44f)](https://1yosh1.github.io/animal-shelter-analytics/)

An analytics warehouse built with **dbt + DuckDB** over the city of Austin's
open-data portal ([Austin Animal Center](https://data.austintexas.gov/),
CC0/public domain), turning 347K raw intake/outcome events (2013–2025) into a
tested, analysis-ready star schema — plus the SQL analyses and charts that
answer the operational questions behind the data.

> **The full analysis with charts lives in
> [`notebooks/analysis.ipynb`](notebooks/analysis.ipynb)** (executed, zero errors).

## 🖥️ Live dashboard

A **live BI dashboard** built with [Evidence](https://evidence.dev) (SQL-in-markdown,
static-site BI) is published to GitHub Pages on every push to `main`:

**→ https://1yosh1.github.io/animal-shelter-analytics/**

Three pages, nine charts: operational KPIs and the 12-year intake/outcome flow,
species outcome mix and the age cliff, and high-volume breed economics. The deploy
workflow rebuilds the *entire pipeline from scratch* on GitHub's runners — downloads
the data from the city portal, runs `dbt build`, materializes the marts to parquet,
and publishes the static site. Nothing is hand-updated.

Run it locally with `make dashboard-build` (or `cd dashboard && npx evidence dev`
for live-reload authoring).

## Headline findings

1. **The shelter is balanced, not structurally overloaded.** Monthly outcomes
   track intakes closely over 12 years; sustained pressure appears only during
   spring/summer "kitten season" spikes — a staffing problem, not a capacity one.
2. **Species inequality is the single biggest operational fact.** **75.4%** of dog
   stays end in a positive outcome (adoption or return-to-owner) vs **56.2%** of
   cats. Cats are also transferred to partner orgs at nearly double the dog rate
   (38.4% vs 21.7%) and wait longer: median 7 vs 6 days, and 25.5% vs 15.8% of
   stays exceed 30 days.
3. **The age cliff is real — but only for cats.** Dogs adopt at 70–79% in *every*
   age band. Cats are U-shaped: kittens (<6 mo) place at 58.9%, but the
   **6–12 month band collapses to 48.0%** — adolescent cats are the hardest
   population to place, and the clearest adoption-campaign target in the data.
4. **Volume ≠ doom.** Pit Bull Mix is the #1 breed by volume (10,026 stays) yet
   places at 75.1% — *better* than several fashionable breeds.
5. **The raw portal data needs guardrails.** Two conflicting datetime formats,
   impossible age strings (`"-1 years"`), location typos, exact duplicate outcome
   rows, and **766 stays whose recorded outcome precedes their intake** — all
   caught and handled by the test suite below, not discovered in a chart.

## Why this project exists

Data analysts are hired to model messy real-world data and answer questions with
it. This repo demonstrates the full craft: raw ingestion → typed staging →
business logic → dimensional marts → tested guarantees → executable analysis.
DuckDB + dbt keep it free, local, and fast (the full build runs in under a second).

## Architecture

```
data/raw/*.csv                      Socrata portal downloads (never edited)
dashboard/                          Evidence BI dashboard (SQL-in-markdown)
  ├─ sources/shelter/*.sql          8 analytical queries materialized to parquet
  └─ pages/*.md                     3 dashboard pages (KPIs, species, breeds)
      │  scripts/load_raw.py
      ▼
raw.intakes, raw.outcomes           DuckDB schema: faithful copy, all varchar
      │  dbt staging (views)
      ▼
stg_intakes, stg_outcomes           typed, renamed, nulls normalized,
                                    age strings → days, timestamps unified
      │  dbt intermediate (view)
      ▼
int_animal_stays                    each intake paired with its next outcome
                                    → stay_days, stay_status
      │  dbt marts (tables)
      ▼
dim_animal        dim_date          star schema
fct_intakes       fct_outcomes
mart_stay_analytics                 one row per completed stay + outcome
                                    category (positive/transfer/negative/…)
```

## What is tested (and why it matters)

`dbt build` runs **8 models + 22 data tests**, including:

- **Grain & reconciliation** — staged rows = fact rows; one row per stay
- **Referential integrity** — not-null/unique keys on every dimension
- **Business rules** — no negative stay lengths can reach the mart
- **Domain monitoring** — every outcome type maps to a known category;
  the unknown-outcome rate must stay under 1% (it is 0.03% today)

`pytest` adds **5 pipeline tests** over a seeded mini-warehouse, covering logic
SQL tests can't express cleanly: duplicate outcome rows never multiply stays,
and outcome-before-intake is *flagged as a data-quality issue* — never silently
paired or hidden. (This test caught a real regression during development.)

## Run it

```bash
make install          # pip install -r requirements/dev.txt
make download         # pull both datasets from the portal (~45 MB)
make load             # load CSVs into DuckDB (raw schema)
make build            # dbt build: 8 models + 22 data tests
make analyze          # re-execute notebooks/analysis.ipynb
pytest                # pipeline logic tests (uses a seeded warehouse)
```

One-liner for the impatient: `make all` (download → load → build → analyze).

## Repository layout

```
├── models/
│   ├── staging/      sources.yml, stg_intakes.sql, stg_outcomes.sql
│   ├── intermediate/ int_animal_stays.sql (the pairing logic)
│   └── marts/        dim_animal, dim_date, fct_intakes, fct_outcomes,
│                     mart_stay_analytics (+ schema tests)
├── analyses/         the five insight queries (executable via dbt)
├── tests/            dbt singular tests + pytest pipeline tests
├── scripts/          download_data, load_raw, make_ci_seed, build notebook
├── notebooks/        executed analysis with charts
└── profiles.yml      dbt-duckdb profile (no global config needed)
```

## Skills demonstrated

SQL (CTEs, window functions, `qualify`, `filter (where …)`, date logic) ·
dbt (staging/intermediate/mart layering, sources, schema + singular tests) ·
DuckDB · data modeling (star schema) · data-quality engineering ·
Python (pandas, matplotlib/seaborn, pytest) · reproducible pipelines (Make, CI).

## Roadmap

- [x] BI layer (Evidence) on the marts — live on GitHub Pages
- [ ] Found-location geocoding → intake heatmap
- [ ] Stay-length forecasting per species (feeds staffing decisions)
