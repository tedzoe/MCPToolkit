#!/usr/bin/env bash
# Adds brave to this project (.mcp.json). Secrets are written as ${VAR} refs, never values.
. "$(dirname "$0")/../_lib.sh"; load_env
mcp_remove brave
need BRAVE_API_KEY
claude mcp add brave -s project -e 'BRAVE_API_KEY=${BRAVE_API_KEY}' -- npx -y @brave/brave-search-mcp-server@2.1.4
