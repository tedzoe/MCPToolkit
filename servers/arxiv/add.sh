#!/usr/bin/env bash
# Adds arxiv to this project (.mcp.json). Secrets are written as ${VAR} refs, never values.
. "$(dirname "$0")/../_lib.sh"; load_env
mcp_remove arxiv
mkdir -p "$ROOT/.cache/arxiv"
claude mcp add -s project arxiv -- uvx arxiv-mcp-server==0.7.2 --storage-path "$ROOT/.cache/arxiv"
