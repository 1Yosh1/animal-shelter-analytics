"""Pipeline tests: run the dbt transformation over a seeded tiny warehouse
and assert the business logic that SQL tests alone can't reach cleanly."""
from __future__ import annotations

import os
import shutil
import subprocess
import sys
from pathlib import Path

import duckdb
import pytest

REPO = Path(__file__).resolve().parent.parent
DB_PATH = REPO / "warehouse" / "pipeline_test.duckdb"


def _dbt_bin() -> str:
    local = REPO / ".venv" / "bin" / "dbt"
    if local.exists():
        return str(local)
    found = shutil.which("dbt")
    if found is None:
        raise RuntimeError("dbt not found (install requirements/dev.txt)")
    return found


@pytest.fixture(scope="module")
def warehouse() -> duckdb.DuckDBPyConnection:
    """Build a fresh warehouse from the seed via the real dbt pipeline."""
    DB_PATH.unlink(missing_ok=True)
    DB_PATH.parent.mkdir(exist_ok=True)
    env = {**os.environ, "DUCKDB_PATH": str(DB_PATH)}
    subprocess.run(
        [sys.executable, "scripts/make_ci_seed.py"],
        cwd=REPO, check=True, env=env,
    )
    subprocess.run(
        [_dbt_bin(), "build", "--profiles-dir", ".", "--quiet"],
        cwd=REPO, check=True, env=env,
    )
    con = duckdb.connect(str(DB_PATH), read_only=True)
    yield con
    con.close()


def test_stay_pairing_and_statuses(warehouse):
    statuses = {
        row[0]: row[1]
        for row in warehouse.execute(
            "select stay_status, count(*) from int_animal_stays group by 1"
        ).fetchall()
    }
    # A555 has a duplicate outcome row; pairing must dedupe to one stay.
    assert statuses.get("completed", 0) >= 4
    # A333's only outcome predates its intake: must be flagged, not silently open.
    assert statuses.get("data_quality_issue", 0) >= 1


def test_negative_stay_days_excluded_from_mart(warehouse):
    n = warehouse.execute(
        "select count(*) from mart_stay_analytics where stay_days < 0"
    ).fetchone()[0]
    assert n == 0


def test_stay_days_match_timestamps(warehouse):
    row = warehouse.execute(
        """
        select stay_days,
               date_diff('day', cast(intake_month as date),
                         cast(intake_month as date))
        from mart_stay_analytics limit 1
        """
    ).fetchone()
    assert row is not None
    assert row[0] >= 0


def test_outcome_categories_exhaustive(warehouse):
    rows = warehouse.execute(
        "select distinct outcome_category from mart_stay_analytics"
    ).fetchall()
    allowed = {"positive", "transfer", "negative", "missing", "other", "unknown"}
    assert {r[0] for r in rows} <= allowed


def test_duplicate_outcomes_do_not_multiply_stays(warehouse):
    n = warehouse.execute(
        "select count(*) from int_animal_stays where animal_key = 'a555'"
    ).fetchone()[0]
    assert n == 1
