#!/usr/bin/env bash
# servers/negtest.sh <name> : negative contract tests for a server, using the same pinned Inspector and the same
# TARGET/CALL as servers/<name>/test.sh. Evidence (stdout, stderr, exit, seconds) lands in evidence/<name>-neg/.
#   N1 schema    : call the test tool (or, if it has no required args, the first tool that does) with {} -> must be rejected.
#   N2 unknown   : call a tool that doesn't exist -> exit 5, code tool_not_found (client-side guard against tools/list).
# Exit codes are Inspector 2.8.0's: 0 ok, 1 usage, 3 auth, 4 unreachable, 5 tool error; 142 = our 150s timeout.
# Never writes .env values: the server command line (which can carry -e KEY=...) is not saved.
. "$(dirname "$0")/_lib.sh"; load_env
name="$1"; t="servers/$name/test.sh"
valid_server_name "$name" && [ -f "$t" ] || { echo "usage: servers/negtest.sh <name>  (one with servers/<name>/test.sh)"; exit 2; }
# Ask the trusted test executable for data; keep credential-bearing args in memory only.
config=$(MCP_TEST_CONFIG_ONLY=1 "$ROOT/$t") || { echo 'FAIL: cannot load test configuration'; exit 1; }
printf '%s' "$config" | jq -e '.name and (.target|type=="array") and (.call|type=="array")' >/dev/null || exit 1
NAME=$(printf '%s' "$config" | jq -r '.name'); TARGET=(); CALL=()
while IFS= read -r -d '' value; do TARGET+=("$value"); done < <(printf '%s' "$config" | jq -j '.target[] | ., "\u0000"')
while IFS= read -r -d '' value; do CALL+=("$value"); done < <(printf '%s' "$config" | jq -j '.call[] | ., "\u0000"')
unset config
[ "${#TARGET[@]}" -gt 0 ] && [ "${#CALL[@]}" -gt 0 ] || { echo 'FAIL: no automated call configured (OAuth servers are untested)'; exit 1; }
fail=0
tool="${CALL[1]}"; d="$ROOT/evidence/$name-neg"; mkdir -p "$d"

cap() {  # cap <id> <inspector args...>
  local id=$1 t0 rc; shift
  printf '%s\n' "$*" > "$d/$id.args"; t0=$(date +%s)
  insp "${TARGET[@]}" "$@" --format json > "$d/$id.stdout"; rc=$?
  cp "$(errlog)" "$d/$id.stderr" 2>/dev/null
  echo "$rc" > "$d/$id.exit"; echo $(( $(date +%s) - t0 )) > "$d/$id.seconds"
}
msg() { { jq -r '[.result.content[]?.text // empty] | join(" ")' "$d/$1.stdout" 2>/dev/null; cat "$d/$1.stderr"; } | clean | head -c 180; }

cap N0-list --method tools/list
req=$(jq -r --arg t "$tool" '.result.tools[]? | select(.name==$t) | (.inputSchema.required // []) | join(",")' "$d/N0-list.stdout" 2>/dev/null)
if [ -z "$req" ]; then   # test tool takes no required args: use the first tool that does, so N1 still proves schema rejection
  alt=$(jq -r '[.result.tools[]? | select((.inputSchema.required // []) | length > 0)][0] | "\(.name)|\(.inputSchema.required | join(","))"' "$d/N0-list.stdout" 2>/dev/null)
  case "$alt" in ""|null*) ;; *) tool="${alt%%|*}"; req="${alt#*|}" ;; esac
fi
if [ "$(cat "$d/N0-list.exit")" != 0 ]; then
  printf '%-10s %-5s %s\n' "$name" FAIL "tools/list exit $(cat "$d/N0-list.exit"): $(msg N0-list)"; exit 1
fi

if [ -z "$req" ]; then
  printf '%-10s %-5s %s\n' "N1 schema" SKIP "no tool on this server has required args"
else
  cap N1-schema --method tools/call --tool-name "$tool" --tool-args-json '{}'
  rc=$(cat "$d/N1-schema.exit")
  if [ "$rc" = 5 ] && jq -e '.result.isError == true' "$d/N1-schema.stdout" >/dev/null 2>&1; then
    printf '%-10s %-5s %s\n' "N1 schema" PASS "rejected as isError (exit 5), requires [$req]: $(msg N1-schema)"
  elif { [ "$rc" = 1 ] || [ "$rc" = 5 ]; } && grep -qiE 'invalid|validation|required|schema|argument|parameter' "$d/N1-schema.stderr" "$d/N1-schema.stdout"; then
    printf '%-10s %-5s %s\n' "N1 schema" PASS "rejected as protocol error (exit $rc), requires [$req]: $(msg N1-schema)"
  else
    fail=1
    printf '%-10s %-5s %s\n' "N1 schema" FAIL "exit $rc (0 = accepted bad input; 4/142 = unreachable/timeout): $(msg N1-schema)"
  fi
fi

cap N2-unknown --method tools/call --tool-name tool_does_not_exist --tool-args-json '{}'
rc=$(cat "$d/N2-unknown.exit")
if [ "$rc" = 5 ] && grep -q tool_not_found "$d/N2-unknown.stderr" "$d/N2-unknown.stdout" 2>/dev/null; then
  printf '%-10s %-5s %s\n' "N2 unknown" PASS "tool_not_found (exit 5)"
else
  fail=1
  printf '%-10s %-5s %s\n' "N2 unknown" FAIL "exit $rc: $(msg N2-unknown)"
fi
echo "Evidence: evidence/$name-neg/"
exit "$fail"
