#!/usr/bin/env bash
# Adopt a reviewed server. Arguments/configuration are data, never evaluated as shell.
# Usage: servers/adhoc.sh NAME stdio COMMAND [ARGS...] [--env NAME] [--query TEXT]
#        servers/adhoc.sh NAME http HTTPS_URL [--header 'Name: ${KEY}'] [--query TEXT]
#        Optional: --call TOOL [--tool-arg key=value]... --yes
#        servers/adhoc.sh --retire NAME
. "$(dirname "$0")/_lib.sh"; load_env; mkdir -p .cache
if [ "${1:-}" = --retire ]; then
  n="${2:-}"
  valid_server_name "$n" && [ -f "servers/$n/ADHOC.md" ] || { echo 'Not an adopted server'; exit 2; }
  [ ! -e "servers/_retired/$n" ] || { echo 'Retired destination already exists'; exit 2; }
  mcp_remove "$n"; mkdir -p servers/_retired
  mv "servers/$n" "servers/_retired/$n"; exit $?
fi
[ "$#" -ge 3 ] || { sed -n '2,6p' "$0"; exit 2; }
name="$1"; transport="$2"; shift 2
valid_server_name "$name" || { echo 'Invalid server name'; exit 2; }
case "$transport" in stdio|http) ;; *) echo 'Transport must be stdio or http'; exit 2;; esac
[ ! -d "servers/$name" ] || [ -f "servers/$name/ADHOC.md" ] || { echo 'Cannot replace a bundled server'; exit 2; }
pos=(); envs=(); headers=(); call=(); query='artificial intelligence'; yes=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --env|--header|--call|--tool-arg|--query)
      [ "$#" -ge 2 ] && [ -n "$2" ] || { echo "Missing value for $1"; exit 2; }
      case "$1" in
        --env) [[ "$2" =~ ^[A-Z_][A-Z0-9_]*$ ]] || { echo 'Invalid environment variable name'; exit 2; }; envs+=("$2");;
        --header) headers+=("$2");;
        --call) call+=(--tool-name "$2");;
        --tool-arg) call+=(--tool-arg "$2");;
        --query) query="$2";;
      esac
      shift 2;;
    --yes) yes=1; shift;;
    *) pos+=("$1"); shift;;
  esac
done
[ "${#pos[@]}" -gt 0 ] || { echo 'Missing command or URL'; exit 2; }
# Header credentials must be env references. Reject control characters, raw secrets and malformed URLs.
for h in ${headers[@]+"${headers[@]}"}; do
  HEADER="$h" node -e 'if (!/^[A-Za-z0-9-]+: *(?:Bearer )?\$\{[A-Z_][A-Z0-9_]*\}$/.test(process.env.HEADER)) process.exit(1)' || {
    echo 'Headers must use Name: ${KEY} or Authorization: Bearer ${KEY}'; exit 2;
  }
done
if [ "$transport" = http ]; then
  [ "${#pos[@]}" -eq 1 ] && [ "${#envs[@]}" -eq 0 ] || { echo 'HTTP takes one URL and --header, not --env'; exit 2; }
  TARGET_URL="${pos[0]}" node -e 'try { const u=new URL(process.env.TARGET_URL); if(u.protocol!=="https:" || u.username || u.password || u.search || u.hash) process.exit(1); } catch { process.exit(1); }' || {
    echo 'Use an HTTPS endpoint without credentials, query string or fragment; put credentials in --header'; exit 2;
  }
else
  [ "${#headers[@]}" -eq 0 ] || { echo 'Use --env for stdio servers'; exit 2; }
  case "${pos[0]}" in
    npx) printf '%s\n' "${pos[@]}" | grep -qE '^(@[^/]+/)?[^@/]+@[0-9]' || { echo 'Pin npx packages with @version'; exit 2; };;
    uvx) printf '%s\n' "${pos[@]}" | grep -qE '==[0-9]' || { echo 'Pin uvx packages with ==version'; exit 2; };;
  esac
fi
if [ "$yes" = 0 ]; then
  printf 'Runs third-party code or calls a remote service: %s\n' "${pos[0]}"
  read -r -p 'Have you reviewed its source, permissions and terms? [y/N] ' answer
  case "$answer" in y|Y) ;; *) exit 1;; esac
fi
d="servers/$name"; mkdir -p "$d"
# All external strings are serialized through jq, never interpolated into scripts.
position=$(jq -n --args '$ARGS.positional' -- "${pos[@]}")
env_json=$(jq -n --args '$ARGS.positional' -- ${envs[@]+"${envs[@]}"})
header_json=$(jq -n --args '$ARGS.positional' -- ${headers[@]+"${headers[@]}"})
call_json=$(jq -n --args '$ARGS.positional' -- ${call[@]+"${call[@]}"})
jq -n --arg transport "$transport" --argjson position "$position" --argjson env "$env_json" \
  --argjson headers "$header_json" --argjson call "$call_json" '
  {transport:$transport,position:$position,env:$env,headers:$headers,call:$call,
   keys:($env + [$headers[] | scan("\\$\\{([A-Z_][A-Z0-9_]*)\\}") | .[0]] | unique),
   target:(if $transport=="http" then [$position[0],"--transport","http"] +
     [$headers[] | "--header", .] else $position + [$env[] | "-e", (. + "=${" + . + "}")] end)}' > "$d/config.json" || exit 1
printf '# %s\n\nUser-adopted third-party server; not verified until all checks pass.\n' "$name" > "$d/ADHOC.md"
for script in add test; do
  {
    printf '#!/usr/bin/env bash\n. "$(dirname "$0")/../_lib.sh"; load_env\nNAME=%s\n' "$name"
    echo '. "$ROOT/servers/adhoc-runtime.sh"'
    echo 'adhoc_load "$NAME" || exit 1'
    if [ "$script" = add ]; then echo 'adhoc_add'; else echo 'adhoc_test'; fi
  } > "$d/$script.sh"
done
printf '#!/usr/bin/env bash\n. "$(dirname "$0")/../_lib.sh"\nclaude mcp remove -s project %s\n' "$name" > "$d/remove.sh"
chmod +x "$d/add.sh" "$d/test.sh" "$d/remove.sh"
. "$ROOT/servers/adhoc-runtime.sh"; adhoc_load "$name" || exit 1
need ${LIST_KEYS[@]+"${LIST_KEYS[@]}"}
echo 'Discovering tools (no tool calls yet)...'
list=$(insp "${TARGET[@]}" --method tools/list --format json); rc=$?
if [ "$rc" = 3 ] && [ "$transport" = http ] && [ "${#headers[@]}" -eq 0 ]; then
  jq '.oauth = true' "$d/config.json" > "$d/config.tmp" && mv "$d/config.tmp" "$d/config.json"
  jq -n --arg name "$name" '{name:$name,status:"OAUTH",detail:"Sign-in required; automated tests NOT run"}' > "$d/last-result.json"
  echo 'OAuth required: connect interactively with /mcp. This server is NOT verified.'
  exit 0
fi
if [ "$rc" != 0 ] || ! printf '%s' "$list" | jq -e '.result.tools | length > 0' >/dev/null; then
  echo 'FAIL: discovery failed; inspect the ignored .cache logs locally'; exit 1
fi
if [ "${#call[@]}" -eq 0 ]; then
  pick=$(printf '%s' "$list" | jq -c '[.result.tools[] | select(.name | test("^(search|list|get|fetch|query|read)(_|[A-Z]|$)")) |
    select((.inputSchema.required // []) as $r | ($r|length)==0 or (($r|length)==1 and ($r[0]|test("^(query|q|search|keyword|keywords|term|text)$"))))][0]')
  [ "$pick" != null ] || { echo 'No read-oriented auto-call found. Rerun with --call TOOL --tool-arg key=value'; exit 1; }
  tool=$(printf '%s' "$pick" | jq -r '.name'); arg=$(printf '%s' "$pick" | jq -r '(.inputSchema.required // [])[0] // empty')
  call=(--tool-name "$tool"); [ -z "$arg" ] || call+=(--tool-arg "$arg=$query")
  call_json=$(jq -n --args '$ARGS.positional' -- "${call[@]}")
  jq --argjson call "$call_json" '.call=$call' "$d/config.json" > "$d/config.tmp" && mv "$d/config.tmp" "$d/config.json"
fi
rm -f "$d/last-result.json"
"$d/test.sh" || exit 1
jq -e '.status=="PASS"' "$d/last-result.json" >/dev/null || { echo 'FAIL: real call did not pass'; exit 1; }
servers/negtest.sh "$name" || {
  jq '.status="FAIL" | .detail="Negative tests failed; adoption not verified"' "$d/last-result.json" > "$d/result.tmp" && mv "$d/result.tmp" "$d/last-result.json"
  echo 'FAIL: negative tests did not pass'; exit 1;
}
echo "Adopted and tested: $name. Connect with servers/use.sh $name; tool approval remains interactive."
