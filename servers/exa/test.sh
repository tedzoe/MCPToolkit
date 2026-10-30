#!/usr/bin/env bash
# Inspector CLI: tools/list, then one cheap real call when keys allow. Prints PASS/FAIL/KEY-NEEDED.
. "$(dirname "$0")/../_lib.sh"; load_env
NAME=exa
TARGET=(https://mcp.exa.ai/mcp --transport http); [ -n "$EXA_API_KEY" ] && TARGET+=(--header "x-api-key: $EXA_API_KEY")
CALL=(--tool-name web_search_exa --tool-arg "query=enterprise AI agent platform funding 2026" --tool-arg "objective=recent market news" --tool-arg numResults=2)
run_test
