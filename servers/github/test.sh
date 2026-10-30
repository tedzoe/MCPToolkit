#!/usr/bin/env bash
# Inspector CLI: tools/list, then one cheap real call when keys allow. Prints PASS/FAIL/KEY-NEEDED.
. "$(dirname "$0")/../_lib.sh"; load_env
NAME=github
LIST_KEYS=(GITHUB_PAT)
TARGET=(https://api.githubcopilot.com/mcp/readonly --transport http --header "Authorization: Bearer $GITHUB_PAT")
CALL=(--tool-name search_repositories --tool-arg "query=model context protocol stars:>1000" --tool-arg perPage=3)
run_test
