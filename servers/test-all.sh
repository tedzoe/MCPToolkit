#!/usr/bin/env bash
# KEY-NEEDED/OAUTH are explicit skips, not proof of readiness.
. "$(dirname "$0")/_lib.sh"; mkdir -p .cache
if [ "$#" -eq 0 ]; then
  for d in servers/*/; do
    n=${d%/}; n=${n##*/}; case "$n" in _*) continue;; esac
    set -- "$@" "$n"
  done
fi
for n in "$@"; do
  valid_server_name "$n" && [ -x "servers/$n/test.sh" ] || { echo "FAIL: unknown server: $n"; exit 2; }
done
pids=(); names=("$@")
for n in "${names[@]}"; do
  "servers/$n/test.sh" > ".cache/test-$n.log" 2>&1 & pids+=("$!")
done
fail=0; i=0
for n in "${names[@]}"; do
  wait "${pids[$i]}" || { echo "$n FAIL: test process failed"; fail=1; }
  cat ".cache/test-$n.log"
  if [ "$(grep -cE "^$n +(PASS|KEY-NEEDED|OAUTH) " ".cache/test-$n.log")" != 1 ] || grep -qE "^$n +FAIL " ".cache/test-$n.log"; then
    echo "$n FAIL: missing or invalid result"; fail=1
  fi
  i=$((i+1))
done
exit "$fail"
