#!/usr/bin/env bash
# servers/use.sh <name> : remove every non-baseline server, ensure fetch, add <name>. Ignores servers/_* (retired).
# Stamps drills/events.log (end of the SELECT phase, read by /drill-review).
. "$(dirname "$0")/_lib.sh"
active=$(ls -d servers/*/ | xargs -n1 basename | grep -v '^_')
valid_server_name "${1:-}" && [ -x "servers/$1/add.sh" ] || { echo "usage: servers/use.sh <name>  (one of: $(echo $active))"; exit 2; }
mkdir -p drills; echo "$(date '+%Y-%m-%d %H:%M:%S') use.sh $1" >> drills/events.log
for n in $active patents-uspto; do [ "$n" = fetch ] || mcp_remove "$n"; done
claude mcp get fetch >/dev/null 2>&1 || servers/fetch/add.sh
servers/"$1"/add.sh || exit $?
st=$(claude mcp list 2>&1 | grep -E "^(fetch|$1):"); echo "$st"
echo "$st" | grep -q 'Pending approval' && echo "(\"Pending approval\" is expected: servers/claude.sh loads .mcp.json via --mcp-config, which needs no approval.)"
echo "Restart Claude with servers/claude.sh so it picks up .env and the new server."
