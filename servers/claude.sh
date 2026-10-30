#!/usr/bin/env bash
# Preserve normal approval. Print mode needs explicit per-tool approval.
# DEMO_MODEL overrides the user's configured default model only when set.
. "$(dirname "$0")/_lib.sh"; load_env
[ -n "${SHOW_ACCOUNT_CONNECTORS:-}" ] || export ENABLE_CLAUDEAI_MCP_SERVERS=false
args=(--mcp-config "$ROOT/.mcp.json" --strict-mcp-config)
[ -z "${DEMO_MODEL:-}" ] || args+=(--model "$DEMO_MODEL")
if [ -n "${MCP_ALLOWED_TOOLS:-}" ]; then
  IFS=',' read -r -a tools <<< "$MCP_ALLOWED_TOOLS"
  for tool in "${tools[@]}"; do
    [[ "$tool" =~ ^mcp__[a-zA-Z0-9_-]+__[a-zA-Z0-9_-]+$ ]] || {
      echo 'MCP_ALLOWED_TOOLS requires comma-separated, fully qualified MCP tool names'; exit 2;
    }
  done
  args+=(--allowedTools "$MCP_ALLOWED_TOOLS")
fi
exec claude "${args[@]}" "$@"
