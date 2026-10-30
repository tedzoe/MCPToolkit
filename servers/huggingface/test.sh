#!/usr/bin/env bash
# Inspector CLI: tools/list, then one cheap real call when keys allow. Prints PASS/FAIL/KEY-NEEDED.
. "$(dirname "$0")/../_lib.sh"; load_env
NAME=huggingface
TARGET=(https://huggingface.co/mcp --transport http); [ -n "$HF_TOKEN" ] && TARGET+=(--header "Authorization: Bearer $HF_TOKEN")
CALL=(--tool-name hub_repo_search --tool-arg query=qwen --tool-arg sort=trendingScore --tool-arg limit=3)
run_test
