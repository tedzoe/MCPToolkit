#!/usr/bin/env bash
# Inspector CLI: tools/list, then one cheap real call when keys allow. Prints PASS/FAIL/KEY-NEEDED.
. "$(dirname "$0")/../_lib.sh"; load_env
NAME=brave
TARGET=(npx @brave/brave-search-mcp-server@2.1.4 -e "BRAVE_API_KEY=${BRAVE_API_KEY:-unset}")
CALL_KEYS=(BRAVE_API_KEY)
CALL=(--tool-name brave_news_search --tool-arg "query=AI PC shipments" --tool-arg count=3)
run_test
