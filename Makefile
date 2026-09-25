.PHONY: install download load build test lint serve analyze dashboard-build all

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

dashboard-build:  ## Build the Evidence dashboard (requires `make build` first)
	cd dashboard && npm install --legacy-peer-deps --no-audit --no-fund
	cd dashboard && npx evidence sources
	cd dashboard && npx evidence build
	./dashboard/scripts/post_build.sh

all: download load build analyze dashboard-build  ## Full pipeline end to end
