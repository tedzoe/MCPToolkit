#!/usr/bin/env bash
# Inspector CLI: tools/list, then one cheap real call when keys allow. Prints PASS/FAIL/KEY-NEEDED.
. "$(dirname "$0")/../_lib.sh"; load_env
NAME=alphavantage
TARGET=("https://mcp.alphavantage.co/mcp?apikey=${ALPHAVANTAGE_API_KEY:-demo}" --transport http)
CALL_KEYS=(ALPHAVANTAGE_API_KEY)
CALL=(--tool-name GLOBAL_QUOTE --tool-arg symbol=IBM)
run_test
