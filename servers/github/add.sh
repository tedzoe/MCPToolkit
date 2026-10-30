#!/usr/bin/env bash
# Adds github to this project (.mcp.json). Secrets are written as ${VAR} refs, never values.
. "$(dirname "$0")/../_lib.sh"; load_env
mcp_remove github
need GITHUB_PAT
claude mcp add -s project -t http github https://api.githubcopilot.com/mcp/readonly -H 'Authorization: Bearer ${GITHUB_PAT}'
