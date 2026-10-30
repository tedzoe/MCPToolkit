# Trusted runtime for adopted servers. Configuration is JSON data, never shell code.
adhoc_load() {
  local config="$ROOT/servers/$1/config.json" value key
  NAME="$1"; TARGET=(); CALL=(); CALL_KEYS=(); LIST_KEYS=()
  jq -e '.transport == "stdio" or .transport == "http"' "$config" >/dev/null || return 1
  while IFS= read -r -d '' value; do TARGET+=("$(expand_refs "$value")"); done < <(
    jq -j '.target[] | ., "\u0000"' "$config")
  while IFS= read -r -d '' value; do CALL+=("$value"); done < <(
    jq -j '.call[] | ., "\u0000"' "$config")
  while IFS= read -r key; do [ -z "$key" ] || LIST_KEYS+=("$key"); done < <(
    jq -r '.keys[]' "$config")
}
adhoc_add() {
  local config="$ROOT/servers/$NAME/config.json" value key transport
  need ${LIST_KEYS[@]+"${LIST_KEYS[@]}"}
  transport=$(jq -r '.transport' "$config")
  local args=(mcp add -s project)
  if [ "$transport" = http ]; then
    args+=(-t http "$NAME" "$(jq -r '.position[0]' "$config")")
    while IFS= read -r -d '' value; do args+=(-H "$value"); done < <(
      jq -j '.headers[] | ., "\u0000"' "$config")
  else
    args+=("$NAME")
    while IFS= read -r key; do [ -z "$key" ] || args+=(-e "$key=\${$key}"); done < <(
      jq -r '.env[]' "$config")
    args+=(--)
    while IFS= read -r -d '' value; do args+=("$value"); done < <(
      jq -j '.position[] | ., "\u0000"' "$config")
  fi
  mcp_remove "$NAME"
  claude "${args[@]}"
}

adhoc_test() {
  [ "${MCP_TEST_CONFIG_ONLY:-}" != 1 ] || { run_test; return $?; }
  if jq -e '.oauth == true' "$ROOT/servers/$NAME/config.json" >/dev/null; then
    jq -n --arg name "$NAME" '{name:$name,status:"OAUTH",detail:"Sign-in required; automated tests NOT run"}' > "$ROOT/servers/$NAME/last-result.json"
    printf '%-18s %-10s %s\n' "$NAME" OAUTH 'sign in via /mcp; automated tests skipped'
    return 0
  fi
  run_test
}
