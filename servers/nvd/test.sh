#!/usr/bin/env bash
# Inspector CLI: tools/list, then one cheap real call when keys allow. Prints PASS/FAIL/KEY-NEEDED.
. "$(dirname "$0")/../_lib.sh"; load_env
NAME=nvd
TARGET=("$ROOT/servers/nvd/run.sh"); [ -n "$NVD_API_KEY" ] && TARGET+=(-e "NVD_API_KEY=$NVD_API_KEY")
CALL=(--tool-name nvd_search_cves --tool-arg keyword=Ivanti --tool-arg kevOnly=true --tool-arg limit=2)
run_test
