# Shared helpers. Sourced by every servers/*/{add,remove,test}.sh (and servers/_retired/*/). bash 3.2 compatible (stock macOS).
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1
INSPECTOR="@modelcontextprotocol/inspector@2.8.0"   # pinned: released 2026-09-23
# Inspector CLI swallows `npx -y` as its own flag, so stdio targets use bare `npx` + this instead.
export npm_config_yes=true

load_env() { if [ -f "$ROOT/.env" ]; then set -a; . "$ROOT/.env"; set +a; fi; }
valid_server_name() { [[ "$1" =~ ^[a-z0-9][a-z0-9-]*$ ]]; }
# Expand literal ${NAME} tokens without interpreting shell syntax.
expand_refs() {
  local rest="$1" out="" prefix token key
  while [[ "$rest" =~ \$\{[A-Z_][A-Z0-9_]*\} ]]; do
    token=${BASH_REMATCH[0]}; key=${token:2:${#token}-3}
    prefix=${rest%%"$token"*}; out="$out$prefix${!key}"; rest=${rest#*"$token"}
  done
  printf '%s' "$out$rest"
}
missing_keys() { local k out=""; for k in "$@"; do [ -n "${!k}" ] || out="$out $k"; done; echo "${out# }"; }
need() { local m; m=$(missing_keys "$@"); [ -z "$m" ] || { echo "KEY-NEEDED: set $m in $ROOT/.env (see .env.example)"; exit 3; }; }

# Run the Inspector CLI with a hard wall-clock limit (macOS has no `timeout`).
# stderr goes to a per-server file: test-all runs servers in parallel, and one shared file let them overwrite each other.
errlog() { echo "$ROOT/.cache/inspector-stderr-${NAME:-adhoc}.log"; }
insp() { perl -e 'alarm shift; exec @ARGV' "${INSPECT_TIMEOUT:-150}" \
  npx "$INSPECTOR" --cli "$@" --connect-timeout 90000 2>"$(errlog)"; }

# One-line printable text: every control char (\r from CSV, \n, \t, ESC, NUL...) becomes a space, runs of spaces squeeze.
# LC_ALL=C is safe for UTF-8: bytes 0x00-0x1F/0x7F never occur inside multibyte sequences.
clean() { LC_ALL=C tr '\000-\037\177' ' ' | tr -s ' '; }

# Claude Code helpers. Project scope = ./.mcp.json. Secrets stay as literal ${VAR}
# references there; Claude expands them at launch (start it with servers/claude.sh).
mcp_remove() { claude mcp remove -s project "$1" >/dev/null 2>&1; true; }

call_ok() { printf '%s' "$1" | jq -e '(.isError!=true) and ((.content//[])|length>0)' >/dev/null 2>&1 \
  && ! printf '%s' "$1" | jq -r '[.content[].text//""]|join(" ")' | grep -qiE '^.{0,60}(error|rate limit|unauthorized|forbidden|invalid api key)'; }
is_rate_limited() { printf '%s' "$1" | grep -qiE 'rate.?limit|429|too many requests'; }

# test harness. Caller sets: NAME, TARGET=(...), CALL=(--tool-name x --tool-arg k=v ...),
# CALL_KEYS=(vars required for a real call), LIST_KEYS=(vars required even for tools/list).
# Result JSON lands next to the calling test.sh, so retired servers keep working.
run_test() {
  if [ "${MCP_TEST_CONFIG_ONLY:-}" = 1 ]; then
    local target_json call_json
    target_json=$(jq -n --args '$ARGS.positional' -- "${TARGET[@]}")
    call_json=$(jq -n --args '$ARGS.positional' -- "${CALL[@]}")
    jq -n --arg name "$NAME" --argjson target "$target_json" --argjson call "$call_json" '{name:$name,target:$target,call:$call}'
    return 0
  fi
  mkdir -p "$ROOT/.cache"
  local out="$(cd "$(dirname "$0")" && pwd)/last-result.json" status detail n names list res lm cm tool
  lm=$(missing_keys ${LIST_KEYS[@]+"${LIST_KEYS[@]}"})
  if [ -n "$lm" ]; then
    status=KEY-NEEDED; n=0; names=""; detail="tools/list needs $lm (auth required before any call)"
  else
    list=$(insp "${TARGET[@]}" --method tools/list)
    n=$(printf '%s' "$list" | jq -r '.tools|length' 2>/dev/null)
    if ! [ "$n" -gt 0 ] 2>/dev/null; then
      n=0; status=FAIL
      detail="tools/list failed: $(printf '%s' "$list" | head -c 300) $(tail -c 300 "$(errlog)" 2>/dev/null)"
    else
      names=$(printf '%s' "$list" | jq -r '[.tools[].name][:8]|join(", ")')
      cm=$(missing_keys ${CALL_KEYS[@]+"${CALL_KEYS[@]}"})
      tool=${CALL[1]}
      if [ -n "$cm" ]; then
        status=KEY-NEEDED; detail="tools/list OK; real call needs $cm"
      elif ! printf '%s' "$list" | jq -e --arg t "$tool" 'any(.tools[]; .name==$t)' >/dev/null; then
        status=FAIL; detail="test tool '$tool' not exposed by server"
      else
        res=$(insp "${TARGET[@]}" --method tools/call "${CALL[@]}")
        # one retry on rate limiting or an empty/transient failure (arXiv and anonymous pools throttle bursts)
        if ! call_ok "$res" && { is_rate_limited "$res" || is_rate_limited "$(cat "$(errlog)" 2>/dev/null)" || [ -z "$res" ]; }; then
          sleep 8; res=$(insp "${TARGET[@]}" --method tools/call "${CALL[@]}"); fi
        if ! call_ok "$res" && is_rate_limited "$res" && [ -n "$RATE_KEY" ] && [ -z "${!RATE_KEY}" ]; then
          status=KEY-NEEDED; detail="tools/list OK; anonymous call rate-limited twice, set $RATE_KEY for reliable calls"
        elif call_ok "$res"; then
          status=PASS; detail="$tool -> $(printf '%s' "$res" | jq -r '[.content[].text//""]|join(" ")' | clean | head -c 220)"
        else
          status=FAIL; detail="$tool call failed: $(printf '%s' "$res" | clean | head -c 200) | stderr: $(tail -c 200 "$(errlog)" 2>/dev/null | clean)"
        fi
      fi
    fi
  fi
  detail=$(printf '%s' "$detail" | clean)   # single choke point: printed line and last-result.json both clean
  jq -n --arg name "$NAME" --arg status "$status" --argjson n "${n:-0}" --arg tools "$names" \
     --arg detail "$detail" --arg at "$(date -u +%FT%TZ)" '{name:$name,status:$status,tool_count:$n,tools:$tools,detail:$detail,tested_at:$at}' > "$out"
  printf '%-18s %-10s tools=%-4s %s\n' "$NAME" "$status" "$n" "$detail"
  [ "$status" = FAIL ] && return 1 || return 0
}
