#!/usr/bin/env bash
# Adds huggingface to this project (.mcp.json). Secrets are written as ${VAR} refs, never values.
. "$(dirname "$0")/../_lib.sh"; load_env
mcp_remove huggingface
if [ -n "$HF_TOKEN" ]; then
  claude mcp add -s project -t http huggingface https://huggingface.co/mcp -H 'Authorization: Bearer ${HF_TOKEN}'
else
  echo "HF_TOKEN not set: adding anonymous (lower rate limits)"; claude mcp add -s project -t http huggingface https://huggingface.co/mcp
fi
