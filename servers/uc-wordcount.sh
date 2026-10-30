#!/usr/bin/env bash
# servers/uc-wordcount.sh <report.md> : words per "## UC<n>" section, bracketed [source IDs] excluded.
# Lives in a file because slash commands substitute $0..$9 inside their own text (that broke the inline awk).
# Prints "UC1: <words>" per use case; exits 1 if any UC is over 120.
f="$1"; [ -f "$f" ] || { echo "usage: servers/uc-wordcount.sh <report.md>"; exit 2; }
out=$(awk '/^## UC[0-9]/{if(h)print h": "w; split($0,a," "); h=a[2]; sub(/:$/,"",h); w=0; next}
     /^## /{if(h)print h": "w; h=""}
     h{gsub(/\[[^]]*\]/,""); w+=NF}
     END{if(h)print h": "w}' "$f")
echo "$out"
echo "$out" | awk -F': ' '$2>120{bad=1} END{exit bad}'
