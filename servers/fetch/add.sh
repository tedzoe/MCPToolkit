#!/usr/bin/env bash
# Adds fetch to this project (.mcp.json). Secrets are written as ${VAR} refs, never values.
. "$(dirname "$0")/../_lib.sh"; load_env
mcp_remove fetch
claude mcp add -s project fetch -- uvx mcp-server-fetch==2026.8.18
