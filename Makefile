.PHONY: install download load build test lint serve analyze all

install:      ## Install dependencies
	python -m pip install -r requirements/dev.txt

download:     ## Download raw data from the Socrata open-data portal
	python scripts/download_data.py

load:         ## Load raw CSVs into the DuckDB warehouse (raw schema)
	python scripts/load_raw.py

build:        ## Run all dbt models + tests
	dbt build --profiles-dir .

test:         ## Run python tests
	pytest

lint:         ## Run the linter
	ruff check scripts tests

serve:        ## Explore the warehouse interactively
	python -c "import duckdb, os; duckdb.connect(os.environ.get('DUCKDB_PATH', 'warehouse/animal_shelter.duckdb')).query('select 42').show()" 2>/dev/null || python -c "import duckdb; duckdb.connect('warehouse/animal_shelter.duckdb')"

analyze:      ## Rebuild the analysis notebook (requires built warehouse)
	python scripts/build_analysis_notebook.py

all: download load build analyze  ## Full pipeline end to end
