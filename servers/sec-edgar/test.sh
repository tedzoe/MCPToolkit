#!/usr/bin/env bash
# Inspector CLI: tools/list, then one cheap real call when keys allow. Prints PASS/FAIL/KEY-NEEDED.
. "$(dirname "$0")/../_lib.sh"; load_env
NAME=sec-edgar
LIST_KEYS=(SEC_EDGAR_USER_AGENT)
UA="${SEC_EDGAR_USER_AGENT:-}"
TARGET=(uvx sec-edgar-mcp==1.1.0 -e "SEC_EDGAR_USER_AGENT=$UA")
CALL=(--tool-name get_recent_filings --tool-arg identifier=NVDA --tool-arg form_type=8-K --tool-arg limit=3)
run_test
