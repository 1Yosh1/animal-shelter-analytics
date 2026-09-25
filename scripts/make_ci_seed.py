"""Build a tiny raw warehouse for CI and pipeline tests (no network access).

Produces warehouse/ci_seed.duckdb with a handful of realistic rows covering
the edge cases the dbt tests protect: negative stay lengths (outcome before
intake), unknown sexes, mixed-age strings, duplicate outcome per animal.
"""
from __future__ import annotations

import os
from pathlib import Path

import duckdb

COLUMNS_INTAKES = [
    "Animal ID", "Name", "DateTime", "MonthYear", "Found Location",
    "Intake Type", "Intake Condition", "Animal Type", "Sex upon Intake",
    "Age upon Intake", "Breed", "Color",
]
COLUMNS_OUTCOMES = [
    "Animal ID", "Date of Birth", "Name", "DateTime", "MonthYear",
    "Outcome Type", "Outcome Subtype", "Animal Type", "Sex upon Outcome",
    "Age upon Outcome", "Breed", "Color",
]

INTAKES = [
    ["A111", "Rex", "01/15/2024 09:00:00 AM", "January 2024", "Nortuh Lamar", "Stray", "Normal", "Dog", "Intact Male", "2 years", "Lab Mix", "Brown"],
    ["A111", "Rex", "06/10/2024 10:30:00 AM", "June 2024", "Nortuh Lamar", "Stray", "Normal", "Dog", "Neutered Male", "2 years", "Lab Mix", "Brown"],
    ["A222", None, "02/20/2024 08:00:00 AM", "February 2024", "Town Lake", "Stray", "Sick", "Cat", "Intact Female", "3 months", "DSH", "Black"],
    ["A333", "Mia", "03/01/2024 07:45:00 AM", "March 2024", "Norht Ec", "Owner Surrender", "Normal", "Dog", "Spayed Female", "1 year", "Beagle", "White"],
    ["A444", None, "04/11/2024 11:00:00 PM", "April 2024", "Austin (TX)", "Wildlife", "Normal", "Other", "Unknown", "1 year", "Bat", "Gray"],
    ["A555", "Zoe", "12/31/2023 06:00:00 PM", "December 2023", "Airport", "Stray", "Normal", "Dog", "Intact Female", "8 weeks", "Husky Mix", "Tan"],
]

OUTCOMES = [
    ["A111", "2022-03-01", "Rex", "03/20/2024 04:00:00 PM", "March 2024", "Return to Owner", None, "Dog", "Neutered Male", "2 years", "Lab Mix", "Brown"],
    ["A111", "2022-03-01", "Rex", "06/15/2024 05:00:00 PM", "June 2024", "Adoption", None, "Dog", "Neutered Male", "2 years", "Lab Mix", "Brown"],
    ["A222", None, None, "04/01/2024 01:00:00 PM", "April 2024", "Transfer", "Partner", "Cat", "Spayed Female", "4 months", "DSH", "Black"],
    ["A333", "2023-01-01", "Mia", "02/28/2024 12:00:00 PM", "February 2024", "Adoption", None, "Dog", "Spayed Female", "1 year", "Beagle", "White"],
    ["A444", None, None, "04/12/2024 06:30:00 AM", "April 2024", "Euthanasia", "Rabies Risk", "Other", "Unknown", "1 year", "Bat", "Gray"],
    ["A555", "2023-10-15", "Zoe", "01/05/2024 03:00:00 PM", "January 2024", "Adoption", None, "Dog", "Spayed Female", "0 years", "Husky Mix", "Tan"],
    ["A555", "2023-10-15", "Zoe", "01/05/2024 03:00:00 PM", "January 2024", "Adoption", None, "Dog", "Spayed Female", "0 years", "Husky Mix", "Tan"],
]


def main() -> None:
    db_path = os.environ.get("DUCKDB_PATH", "warehouse/ci_seed.duckdb")
    Path(db_path).parent.mkdir(parents=True, exist_ok=True)
    con = duckdb.connect(db_path)
    con.execute("create schema if not exists raw")

    def register(name, columns, rows):
        import pandas as pd

        df = pd.DataFrame(rows, columns=columns).astype(str).replace("None", None)
        con.register(name, df)
        con.execute(f"create or replace table raw.{name} as select * from {name}")
        con.unregister(name)

    register("intakes", COLUMNS_INTAKES, INTAKES)
    register("outcomes", COLUMNS_OUTCOMES, OUTCOMES)

    print("seeded:", con.execute("select count(1) from raw.intakes").fetchone()[0],
          "intakes,", con.execute("select count(1) from raw.outcomes").fetchone()[0],
          "outcomes")
    con.close()


if __name__ == "__main__":
    main()
