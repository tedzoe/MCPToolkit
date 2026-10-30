#!/usr/bin/env bash
# servers/drill.sh : practice run. Random topic from drills/topics.txt, then the same menu flow as a live run (servers/go.sh)
# plus a spoken 20-min timer (alerts at 4, 9, 16, 20), automatic drills/log.md entry, and an offer to run /drill-review.
# DRILL_SECS_PER_MIN=1 runs a 20-second test drill. DRILL_TOPIC="..." forces a topic.
. "$(dirname "$0")/_lib.sh"
last=$(grep '^## ' drills/log.md 2>/dev/null | tail -1 | sed -E 's/^## [0-9-]+ [0-9:]+: //')
line=$(grep -v '^#' drills/topics.txt | grep . | awk -v last="$last" 'BEGIN{srand()} { t=$0; sub(/[[:space:]]+#.*$/,"",t); if (t!=last) a[++n]=$0 } END{print a[int(rand()*n)+1]}')   # never repeat the previous drill's topic
[ -n "$DRILL_TOPIC" ] && line=$(grep -F "$DRILL_TOPIC" drills/topics.txt | head -1) && [ -z "$line" ] && line="$DRILL_TOPIC"
topic=$(printf '%s' "$line" | sed -E 's/[[:space:]]+#.*$//')
staged=$(printf '%s' "$line" | sed -nE 's/.*# staged: ([a-z0-9-]+).*/\1/p')
DRILL=1 STAGED="$staged" exec servers/go.sh "$topic"
