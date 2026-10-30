#!/usr/bin/env bash
# servers/go.sh ["<topic>"] : one-terminal flow. Menu -> use.sh -> test.sh -> Claude with /usecases already running.
#   Live:       servers/go.sh "<topic>"      (no timer, no audio, no drill log)
#   Practice:   servers/drill.sh             (sets DRILL=1: random topic, spoken timer, auto log, offers /drill-review)
# Menu keys: Enter = recommended server, a number = that server, p = /pick-server live search, q = quit.
# Every step is stamped in drills/events.log so /drill-review can time the phases. bash 3.2 compatible.
. "$(dirname "$0")/_lib.sh"
mkdir -p drills .cache
DRILL="${DRILL:-}"
topic="$1"
[ -n "$topic" ] || read -r -p "Topic: " topic
[ -n "$topic" ] || { echo "usage: servers/go.sh \"<topic>\""; exit 2; }

stamp() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> drills/events.log; }
lc() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }

# ---- recommendation: topics.txt "# staged: x" wins, else the RUNBOOK topic map, else exa
recommend() {   # sets rec + rec_why (no subshell, so both survive). Whole-word matching: "sector" isn't "sec", "report" isn't "repo".
  local t; t=$(lc "$1")
  hit() { printf '%s' "$t" | grep -qiwE "$1"; }
  if [ -n "$STAGED" ]; then rec="$STAGED"; rec_why="pre-verified for this topic (drills/topics.txt)"; return; fi
  rec_why="matches the RUNBOOK topic map"
  if hit 'vulnerability|vulnerabilities|cve|cves|security|cybersecurity|cyber|exploit|exploits|ransomware|patching'; then rec=nvd
  elif hit 'patent|patents|ip|intellectual'; then rec=exa; rec_why="patents-google can only look up known patent numbers here (search needs BigQuery), so exa searches Google Patents pages"
  elif hit 'open-source|github|developer|developers|repo|repos|repository|repositories' || printf '%s' "$t" | grep -qi 'open source'; then rec=github
  elif hit 'genai|llm|llms|huggingface|hugging|open-weight|foundation' || { hit 'model|models' && hit 'ai|ml|language|weight|weights|generative'; }; then rec=huggingface
  elif hit 'financial|financials|finance|capex|earnings|revenue|revenues|profitability|margins|filings|10-k|10-q|edgar' || printf '%s' "$t" | grep -qiE 'vendor health|public compan'; then rec=sec-edgar
  elif hit 'research|paper|papers|quantum|academic|arxiv|emerging'; then rec=arxiv
  else rec=exa; rec_why="no pre-verified server fits this topic; exa (web search) is the fallback, and p searches the registry live"; unstaged=1
  fi
}
backup_for() {
  case "$1" in
    huggingface) echo arxiv ;; github) echo huggingface ;; sec-edgar) echo exa ;;
    arxiv|nvd|patents-google|alphavantage|semantic-scholar) echo exa ;; *) echo exa ;;
  esac
}
# Parse registry recommendations as data; never execute shell text.
safe_adhoc_args() { node "$ROOT/servers/adopt-command.js" --check "$1"; }
status_of() { jq -r '.status // "UNTESTED"' "servers/$1/last-result.json" 2>/dev/null || echo UNTESTED; }

servers=$(ls -d servers/*/ | xargs -n1 basename | grep -v '^_' | grep -vx fetch)
set -- $servers; names=("$@")
unstaged=""; recommend "$topic"
criteria_names=(x provenance maintenance transport-auth read-only rate-limits-cost data-license fit)
criteria=""; picked=""; broke=""; picked_live=""

# ---- drill extras: spoken timer (silent on screen so it never garbles Claude's UI) + log entry
timer_pid=""; start=$(date '+%Y-%m-%d %H:%M:%S'); start_s=$(date +%s); status=aborted; logged=""
speak() { command -v say >/dev/null 2>&1 && say "$1" >/dev/null 2>&1
          command -v osascript >/dev/null 2>&1 && osascript -e "display notification \"$1\" with title \"MCP drill\"" >/dev/null 2>&1; }
start_timer() {
  local spm="${DRILL_SECS_PER_MIN:-60}"
  ( exec 2>/dev/null; sleep $((4*spm));  speak "Minute 4. Connect phase."
    sleep $((5*spm));  speak "Minute 9. Use cases should be running."
    sleep $((7*spm));  speak "Minute 16. Rehearse. Pick the strongest finding per use case."
    sleep $((4*spm));  speak "Time. 20 minutes up." ) &
  timer_pid=$!; disown "$timer_pid" 2>/dev/null   # no "Terminated" noise when stopped
}
stop_timer() { [ -n "$timer_pid" ] && { pkill -P "$timer_pid" 2>/dev/null; kill "$timer_pid" 2>/dev/null; }; timer_pid=""; }
log_entry() {
  [ -n "$DRILL" ] && [ -z "$logged" ] || return 0
  logged=1; local el=$(( $(date +%s) - start_s ))
  # replace a provisional entry for this drill (written at Claude launch) instead of appending a second one
  if grep -q "^## $start: " drills/log.md 2>/dev/null; then
    START="$start" perl -0pi -e 's/\n## \Q$ENV{START}\E: .*?(?=\n## |\z)//s' drills/log.md
  fi
  { echo; echo "## $start: $topic"; echo "- start: $start"
    echo "- end: $(date '+%Y-%m-%d %H:%M:%S') ($status, $((el/60))m $((el%60))s)"
    echo "- server picked: ${picked:-none}${picked_live:+ (after /pick-server)}"
    echo "- what broke / fix: ${broke:-none}"
    echo "- notes: criteria stated: ${criteria:-none recorded}${picked_live:+; /pick-server run, output in .cache/pick-server-last.md}"
  } >> drills/log.md
  echo "Logged to drills/log.md"
}
cleanup() { stop_timer; log_entry; }
trap cleanup EXIT; trap 'exit 130' INT

menu() {
  echo; printf 'TOPIC: %s\n' "$topic"; echo
  local i=1 n s mark
  for n in "${names[@]}"; do
    s=$(status_of "$n"); mark="  "; [ "$n" = "$rec" ] && mark="★ "
    printf ' %s%2d) %-18s %s\n' "$mark" "$i" "$n" "$s"; i=$((i+1))
  done
  echo "     p) /pick-server: search the MCP registry live for this topic"
  echo "     a) adopt a server the search found (paste the servers/adhoc.sh line it printed)"
  echo "  ★ = $rec: $rec_why"
  echo "     q) quit"
}
choose() {
  local ans
  while :; do
    menu
    if [ -z "$picked_live" ]; then
      # always search live first, even when a pre-verified one fits
      if [ -n "$unstaged" ]; then echo "This topic has no pre-verified server. Recommended: press Enter to run the live registry search (p) first."
      else echo "★ $rec is pre-verified, but a live search is the safer habit. Recommended: press Enter to search (p); a pre-verified winner keeps ★."; fi
      read -r -p "Type ONE thing, then Enter.  Enter = search (p) | 1-${#names[@]} = that server | q = quit: " ans
      [ -z "$ans" ] && ans=p
    else
      read -r -p "Type ONE thing, then Enter.  Enter = ★ $rec | 1-${#names[@]} = that server | p = search registry | q = quit: " ans
    fi
    case "$ans" in
      "") echo "$rec" >&3; return 0 ;;
      q|Q) return 1 ;;
      a|A) echo "Paste everything after 'servers/adhoc.sh', e.g.:  pricing stdio uvx some-mcp==1.2.3 --query \"GPU\""
           read -r -p "adhoc> " adl
           [ -n "$adl" ] || continue
           if ! safe_adhoc_args "$adl"; then echo "Refused: the line must be '<name> stdio|http ...' with no ; | & \` < > \\ or \$( in it."; continue; fi
           stamp "adhoc: $adl"
           if node "$ROOT/servers/adopt-command.js" --run "$adl"; then
             new=$(set -- $adl; echo "$1"); stamp "adopted $new"
             servers=$(ls -d servers/*/ | xargs -n1 basename | grep -v '^_' | grep -vx fetch); set -- $servers; names=("$@")
             rec="$new"; rec_why="adopted live from /pick-server; test.sh + negtest.sh passed"; unstaged=""
           else
             broke="$broke${broke:+; }adhoc failed: $adl"; echo "Adoption failed. ★ stays $rec."
           fi ;;
      p|P) stamp "pick-server start: $topic"; picked_live=1
           echo "Searching the registry (about 1-2 min)..."
           psf=".cache/pick-server-$(date +%Y%m%d-%H%M%S).md"
           servers/claude.sh -p "/pick-server $topic" | tee "$psf"; cp "$psf" .cache/pick-server-last.md
           stamp "pick-server done ($psf)"
           next=$(grep -E '^NEXT: servers/(use|adhoc)\.sh ' "$psf" | tail -1 | sed 's/^NEXT: //')
           # fallback if the model skipped the NEXT line: the last use.sh / adhoc.sh command it printed anywhere
           [ -n "$next" ] || next=$(grep -oE 'servers/(use\.sh [a-z0-9-]+|adhoc\.sh [^`]*)' "$psf" | tail -1)
           if [ -z "$next" ]; then
             echo; echo "The search didn't name a command. Its pick is in the table above: press Enter for ★ $rec, or type that server's number. Don't search again."
           fi
           case "$next" in
             "servers/use.sh "*)
               w=$(echo "$next" | awk '{print $2}')
               if valid_server_name "$w" && [ -x "servers/$w/add.sh" ]; then rec="$w"; rec_why="/pick-server winner, pre-verified"; unstaged=""; echo; echo "Search winner: ★ $w (pre-verified). Press Enter to use it."; fi ;;
             "servers/adhoc.sh "*)
               args="${next#servers/adhoc.sh }"
               # the line came from model output built on registry/README text: allow only plain args and ${VAR} refs
               if ! safe_adhoc_args "$args"; then
                 echo "Search suggested an adoption line I won't run automatically (unsafe or malformed):"; echo "  $next"; echo "Use 'a' to paste a corrected one, or Enter for ★ $rec."
               else
                 w=$(echo "$args" | awk '{print $1}')
                 echo; echo "Search winner $w isn't pre-verified. Adopting it runs:"; echo "  $next"
                 read -r -p "Adopt now (test + negative tests)? [y/N] " a
                 case "$a" in n|N|'') echo "Skipped. ★ stays $rec." ;;
                   y|Y) stamp "adhoc: $args"
                      if node "$ROOT/servers/adopt-command.js" --yes "$args"; then
                        stamp "adopted $w"
                        servers=$(ls -d servers/*/ | xargs -n1 basename | grep -v '^_' | grep -vx fetch); set -- $servers; names=("$@")
                        rec="$w"; unstaged=""
                        if [ "$(status_of "$w")" = OAUTH ]; then rec_why="adopted live; OAuth: sign in via /mcp, automated tests skipped"; else rec_why="adopted live from /pick-server; real call + negative tests passed"; fi
                        echo "Adopted. Press Enter to use ★ $w."
                      else broke="$broke${broke:+; }adhoc failed: $w"; echo "Adoption failed. ★ stays $rec."; fi ;;
                 esac
               fi ;;
           esac ;;
      *[!0-9]*) echo "\"$ans\" isn't an option. Type a single server number (1-${#names[@]}), p, q, or just press Enter." ;;
      *) if [ "$ans" -ge 1 ] && [ "$ans" -le "${#names[@]}" ]; then echo "${names[$((ans-1))]}" >&3; return 0; fi
         echo "\"$ans\" isn't an option. Type a single server number (1-${#names[@]}), p, q, or just press Enter." ;;
    esac
  done
}
ask_criteria() {
  [ -n "$DRILL" ] || return 0
  echo "Criteria you said out loud: 1 provenance  2 maintenance  3 transport/auth  4 read-only  5 rate limits/cost  6 license  7 fit"
  local d c=""; read -r -p "Digits, e.g. 1347 (Enter = none): " d
  d=$(printf '%s' "$d" | tr -cd '1-7')
  while [ -n "$d" ]; do c="$c${c:+, }${criteria_names[${d:0:1}]}"; d=${d:1}; done
  criteria="$c"; [ -n "$c" ] && stamp "criteria stated: $c"
}

[ -n "$DRILL" ] && { start_timer; stamp "drill start: $topic"; }
stamp "go.sh topic: $topic (recommended $rec)"
while :; do
  exec 3>.cache/choice; choose || exit 0; exec 3>&-
  name=$(cat .cache/choice)
  s=$(status_of "$name")
  if [ "$s" != PASS ] && [ "$s" != OAUTH ]; then
    read -r -p "$name last tested $s (it will be checked before launch). Use it anyway? [y/N] " a
    case "$a" in y|Y) ;; *) continue ;; esac
  fi
  if [ "$name" != "$rec" ]; then
    read -r -p "★ for this topic is $rec ($rec_why). Use $name instead? [y/N] " a
    case "$a" in y|Y) broke="$broke${broke:+; }chose $name over ★ $rec" ;; *) continue ;; esac
  fi
  [ -z "$criteria" ] && ask_criteria
  echo; echo "== Connecting $name"
  if ! servers/use.sh "$name"; then broke="$broke${broke:+; }use.sh $name failed"; rec=$(backup_for "$name"); echo "use.sh failed. Backup is ★ $rec."; continue; fi
  echo; echo "== Testing $name (Inspector: tools/list + one real call)"
  servers/"$name"/test.sh; s=$(status_of "$name"); stamp "test.sh $name $s"
  if [ "$s" != PASS ] && [ "$s" != OAUTH ]; then
    broke="$broke${broke:+; }$name test $s"; rec=$(backup_for "$name")
    echo; echo "$name is $s. Backup is ★ $rec. Pick it, or p to search."; continue
  fi
  picked="$name"; break
done

if [ -n "$DRILL" ]; then status="in progress"; log_entry; logged=""; fi   # provisional entry so an in-session /drill-review finds this drill
echo; echo "== Launching Claude with /usecases $topic $picked"
[ -n "$DRILL" ] && echo "   When done rehearsing: /exit, then Enter here runs /drill-review (an in-session review scores rehearse as not recorded)."
# /run = /usecases for this topic+server, so nothing needs retyping after an OAuth sign-in (or a restart)
{ echo "---"; echo "description: Run /usecases for the current topic and server (written by go.sh)"
  echo "allowed-tools: Read, Bash(date:*), Bash(mkdir:*), Bash(servers/uc-wordcount.sh:*), Write, Edit"
  echo "---"; echo; echo "Read \`.claude/commands/usecases.md\` and follow it exactly. Its arguments are: $topic $picked"; } > .claude/commands/run.md
stamp "claude.sh start /usecases $picked"
if [ "$(status_of "$picked")" = OAUTH ]; then
  echo; echo "== $picked needs a browser sign-in. Claude opens on /mcp:"
  echo "   1) choose $picked → Authenticate  2) finish in the browser  3) Esc  4) type /run"
  stamp "oauth sign-in for $picked"
  servers/claude.sh "/mcp"
else
  servers/claude.sh "/usecases $topic $picked"
fi
stamp "claude.sh exit"

[ -n "$DRILL" ] || exit 0
stop_timer; status=completed; log_entry
read -r -p "Run /drill-review now? [Y/n] " a
case "$a" in n|N) echo "Later: servers/claude.sh \"/drill-review\"";; *) servers/claude.sh "/drill-review";; esac
