#!/usr/bin/env bash
# Post-build fix for GitHub Pages: Pages has no server-side redirects and
# serves 404.html for unknown paths. Duplicating the index as a soft fallback
# keeps deep links (and hard reloads) working.
set -euo pipefail
cd "$(dirname "$0")/.."

cp build/index.html build/404.html
echo "created build/404.html fallback"
