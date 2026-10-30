#!/usr/bin/env bash
# Adds tavily to this project (.mcp.json). Secrets are written as ${VAR} refs, never values.
. "$(dirname "$0")/../_lib.sh"; load_env
mcp_remove tavily
need TAVILY_API_KEY
claude mcp add -s project -t http tavily 'https://mcp.tavily.com/mcp/?tavilyApiKey=${TAVILY_API_KEY}'
