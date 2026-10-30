#!/usr/bin/env bash
# Adds semantic-scholar to this project (.mcp.json). Secrets are written as ${VAR} refs, never values.
. "$(dirname "$0")/../_lib.sh"; load_env
mcp_remove semantic-scholar
E=(); [ -n "$SEMANTIC_SCHOLAR_API_KEY" ] && E=(-e 'SEMANTIC_SCHOLAR_API_KEY=${SEMANTIC_SCHOLAR_API_KEY}')
claude mcp add semantic-scholar -s project ${E[@]+"${E[@]}"} -- uvx s2-mcp-server==1.7.4
