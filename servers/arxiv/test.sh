#!/usr/bin/env bash
# Inspector CLI: tools/list, then one cheap real call when keys allow. Prints PASS/FAIL/KEY-NEEDED.
. "$(dirname "$0")/../_lib.sh"; load_env
NAME=arxiv
mkdir -p .cache/arxiv; TARGET=(uvx arxiv-mcp-server==0.7.2 --storage-path "$ROOT/.cache/arxiv")
CALL=(--tool-name search_papers --tool-arg "query=agentic AI market" --tool-arg max_results=2)
run_test
