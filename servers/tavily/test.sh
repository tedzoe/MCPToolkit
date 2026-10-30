#!/usr/bin/env bash
# Inspector CLI: tools/list, then one cheap real call when keys allow. Prints PASS/FAIL/KEY-NEEDED.
. "$(dirname "$0")/../_lib.sh"; load_env
NAME=tavily
LIST_KEYS=(TAVILY_API_KEY)
TARGET=("https://mcp.tavily.com/mcp/?tavilyApiKey=$TAVILY_API_KEY" --transport http)
CALL=(--tool-name tavily_search --tool-arg "query=AI infrastructure spending 2026" --tool-arg max_results=2)
run_test
