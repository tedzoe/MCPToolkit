#!/usr/bin/env bash
# Inspector CLI: tools/list, then one cheap real call when keys allow. Prints PASS/FAIL/KEY-NEEDED.
. "$(dirname "$0")/../_lib.sh"; load_env
NAME=semantic-scholar
TARGET=(uvx s2-mcp-server==1.7.4); [ -n "$SEMANTIC_SCHOLAR_API_KEY" ] && TARGET+=(-e "SEMANTIC_SCHOLAR_API_KEY=$SEMANTIC_SCHOLAR_API_KEY")
RATE_KEY=SEMANTIC_SCHOLAR_API_KEY
CALL=(--tool-name semantic_scholar_search_papers --tool-arg 'params={"query":"retrieval augmented generation","limit":2}')
run_test
