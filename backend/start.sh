#!/bin/bash
set -e
cd "$(dirname "$0")"

echo "→ Installing dependencies..."
pip install -r requirements.txt -q

echo "→ Starting Nighthawk News backend on http://localhost:8000"
echo "   First scrape begins immediately; articles appear within ~15 seconds."
echo "   Cache refreshes automatically every 30 minutes."
echo "   Press Ctrl+C to stop."
echo ""

python main.py
