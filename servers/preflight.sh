#!/usr/bin/env bash
# Default: local prerequisites only. --live [names...] also makes real server calls.
. "$(dirname "$0")/_lib.sh"
live=0
case "${1:-}" in
  --live) live=1; shift;;
  --help) echo 'Usage: servers/preflight.sh [--live [server ...]]'; exit 0;;
  '') ;;
  *) echo 'Usage: servers/preflight.sh [--live [server ...]]'; exit 2;;
esac
fail=0
for cmd in bash node npx uvx jq curl perl claude; do
  if command -v "$cmd" >/dev/null 2>&1; then echo "PASS dependency: $cmd"
  else echo "FAIL missing dependency: $cmd (see README.md)"; fail=1; fi
done
[ "$fail" = 0 ] || exit 1
node -e 'if (+process.versions.node.split(".")[0] < 22) process.exit(1)' || {
  echo 'FAIL Node.js 22 or newer required'; exit 1;
}
if jq -e '.mcpServers | type == "object" and has("fetch") and length <= 2' .mcp.json >/dev/null 2>&1; then
  echo 'PASS config: fetch plus at most one selected server'
else echo 'FAIL invalid .mcp.json; run servers/use.sh fetch'; exit 1; fi
echo 'INFO Claude login and model access are checked when you launch Claude.'
echo 'INFO .env is optional for fetch. Add only the credentials your selected server needs.'
if [ "$live" = 1 ]; then
  [ "$#" -gt 0 ] || set -- fetch
  servers/test-all.sh "$@" || exit 1
  for n in "$@"; do
    jq -e '.status == "PASS"' "servers/$n/last-result.json" >/dev/null 2>&1 || {
      echo "FAIL $n is not PASS; configure its credentials or choose another server"; exit 1;
    }
  done
fi
echo 'PASS preflight'
