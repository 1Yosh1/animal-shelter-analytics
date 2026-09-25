"""Download the Austin Animal Center intake/outcome datasets.

Data portal: https://data.austintexas.gov
- Intakes:  https://data.austintexas.gov/Resource-Support/wter-evkm
- Outcomes: https://data.austintexas.gov/Resource-Support/9t4d-g238
"""
from __future__ import annotations

import sys
import urllib.request
from pathlib import Path

DATASETS = {
    "intakes.csv": "https://data.austintexas.gov/api/views/wter-evkm/rows.csv?accessType=DOWNLOAD",
    "outcomes.csv": "https://data.austintexas.gov/api/views/9t4d-g238/rows.csv?accessType=DOWNLOAD",
}
RAW_DIR = Path(__file__).resolve().parent.parent / "data" / "raw"
MIN_BYTES = 5_000_000  # sanity floor: full files are ~20-25 MB


def download() -> None:
    RAW_DIR.mkdir(parents=True, exist_ok=True)
    for filename, url in DATASETS.items():
        target = RAW_DIR / filename
        print(f"Downloading {filename} ...")
        try:
            urllib.request.urlretrieve(url, target)
        except Exception as exc:  # noqa: BLE001
            print(f"FAILED: {exc}\nDownload manually from the URLs above into {RAW_DIR}")
            sys.exit(1)
        size = target.stat().st_size
        if size < MIN_BYTES:
            print(f"File looks truncated ({size:,} bytes)")
            sys.exit(1)
        print(f"  ok: {size / 1e6:.1f} MB")


if __name__ == "__main__":
    download()
