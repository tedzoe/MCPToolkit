#!/usr/bin/env bash
# Adds exa to this project (.mcp.json). Secrets are written as ${VAR} refs, never values.
. "$(dirname "$0")/../_lib.sh"; load_env
mcp_remove exa
if [ -n "$EXA_API_KEY" ]; then
  claude mcp add -s project -t http exa https://mcp.exa.ai/mcp -H 'x-api-key: ${EXA_API_KEY}'
else
  echo "EXA_API_KEY not set: adding anonymous free tier"; claude mcp add -s project -t http exa https://mcp.exa.ai/mcp
fi
