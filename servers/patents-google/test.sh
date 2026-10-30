#!/usr/bin/env bash
# Inspector CLI: tools/list, then one cheap real call when keys allow. Prints PASS/FAIL/KEY-NEEDED.
. "$(dirname "$0")/../_lib.sh"; load_env
NAME=patents-google
TARGET=(uvx deeparchi-patent-mcp==1.9.2)
CALL=(--tool-name get_patent --tool-arg publication_number=US10452978B2)
run_test
