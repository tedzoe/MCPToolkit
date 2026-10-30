#!/usr/bin/env bash
# Inspector CLI: tools/list, then one cheap real call when keys allow. Prints PASS/FAIL/KEY-NEEDED.
. "$(dirname "$0")/../_lib.sh"; load_env
NAME=fetch
TARGET=(uvx mcp-server-fetch==2026.8.18)
CALL=(--tool-name fetch --tool-arg url=https://example.com --tool-arg max_length=300)
run_test
