#!/bin/bash
set -e
cd "$(dirname "$0")"

# Create venv on first run
if [ ! -d ".venv" ]; then
  echo "→ Creating virtual environment..."
  python3 -m venv .venv
fi

echo "→ Installing dependencies..."
.venv/bin/pip install -r requirements.txt -q

# Free port 8000 if something is already using it (lsof exits 1 when nothing
# is found, which would abort the script under set -e — pipe through xargs
# so the whole expression always exits 0)
lsof -ti :8000 2>/dev/null | xargs kill -9 2>/dev/null || true

echo "→ Starting NighthawkNews backend on http://localhost:8000"
echo "   First scrape begins immediately; articles appear within ~15 seconds."
echo "   Cache refreshes automatically every 30 minutes."
echo "   Press Ctrl+C to stop."
echo ""

.venv/bin/python main.py
