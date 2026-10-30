#!/usr/bin/env bash
# Adds nvd to this project (.mcp.json). Secrets are written as ${VAR} refs, never values.
. "$(dirname "$0")/../_lib.sh"; load_env
mcp_remove nvd
E=(); [ -n "$NVD_API_KEY" ] && E=(-e 'NVD_API_KEY=${NVD_API_KEY}')
claude mcp add nvd -s project ${E[@]+"${E[@]}"} -- "$ROOT/servers/nvd/run.sh"
