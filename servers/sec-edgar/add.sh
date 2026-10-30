#!/usr/bin/env bash
# Adds sec-edgar to this project (.mcp.json). Secrets are written as ${VAR} refs, never values.
. "$(dirname "$0")/../_lib.sh"; load_env
mcp_remove sec-edgar
need SEC_EDGAR_USER_AGENT
claude mcp add sec-edgar -s project -e 'SEC_EDGAR_USER_AGENT=${SEC_EDGAR_USER_AGENT}' -- uvx sec-edgar-mcp==1.1.0
