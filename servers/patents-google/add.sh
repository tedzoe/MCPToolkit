#!/usr/bin/env bash
# Adds patents-google to this project (.mcp.json). Secrets are written as ${VAR} refs, never values.
. "$(dirname "$0")/../_lib.sh"; load_env
mcp_remove patents-google
claude mcp add -s project patents-google -- uvx deeparchi-patent-mcp==1.9.2
