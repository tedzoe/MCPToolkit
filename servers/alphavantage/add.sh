#!/usr/bin/env bash
# Adds alphavantage to this project (.mcp.json). Secrets are written as ${VAR} refs, never values.
. "$(dirname "$0")/../_lib.sh"; load_env
mcp_remove alphavantage
if [ -n "$ALPHAVANTAGE_API_KEY" ]; then
  claude mcp add -s project -t http alphavantage 'https://mcp.alphavantage.co/mcp?apikey=${ALPHAVANTAGE_API_KEY}'
else
  echo "ALPHAVANTAGE_API_KEY not set: using public demo key (IBM symbol only)"; claude mcp add -s project -t http alphavantage "https://mcp.alphavantage.co/mcp?apikey=demo"
fi
