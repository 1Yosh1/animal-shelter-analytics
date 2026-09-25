"""Load raw CSVs into a DuckDB warehouse (schema: raw).

The raw layer is a faithful, untouched copy of the portal data: keep the mess
in the raw layer so dbt transformations are testable and reversible.
"""
from __future__ import annotations

import os
from pathlib import Path

import duckdb

REPO = Path(__file__).resolve().parent.parent
RAW_DIR = REPO / "data" / "raw"
WAREHOUSE_DIR = REPO / "warehouse"
DB_PATH = Path(os.getenv("DUCKDB_PATH", WAREHOUSE_DIR / "animal_shelter.duckdb"))

FILES = {
    "intakes": RAW_DIR / "intakes.csv",
    "outcomes": RAW_DIR / "outcomes.csv",
}


def load() -> None:
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    con = duckdb.connect(str(DB_PATH))
    try:
        con.execute("create schema if not exists raw")
        for table, path in FILES.items():
            if not path.exists():
                raise SystemExit(
                    f"Missing {path}. Run `make download` (or scripts/download_data.py) first."
                )
            # Load everything as varchar: the dbt staging layer owns typing.
            con.execute(
                f"""
                create or replace table raw.{table} as
                select * from read_csv_auto('{path}', all_varchar=true, header=true)
                """
            )
            count = con.execute(f"select count(1) from raw.{table}").fetchone()[0]
            print(f"raw.{table}: {count:,} rows")
    finally:
        con.close()
    print(f"Warehouse: {DB_PATH}")


if __name__ == "__main__":
    load()
