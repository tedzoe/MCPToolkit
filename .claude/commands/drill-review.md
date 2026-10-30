---
description: Score the latest drill against the RUNBOOK phases, log the review
argument-hint: (none)
allowed-tools: Read, Edit, Bash(ls:*), Bash(stat:*), Bash(grep:*), Bash(tail:*), Bash(head:*), Bash(date:*)
---

Review the most recent drill. Use only evidence from files. When something wasn't recorded, write "not recorded" and never guess. Never read or print `.env`.

## 1. Gather (one turn, parallel)
- Read `drills/log.md`. The **latest entry** is the last `## ` block. Take its start, end, status, server picked, what broke and notes.
- Run `ls -t outputs/*.md | head -1` and `stat -f '%Sm' -t '%Y-%m-%d %H:%M:%S' <that file>`, then Read the file (the **report**).
- Run `tail -20 drills/events.log 2>/dev/null` (`use.sh` timestamps).
- Run `date '+%Y-%m-%d %H:%M'`.
If the report's mtime falls outside the drill's start–end window (allow +5 min), say "report not from this drill" and score the report anyway, flagged.
If the latest entry already has a `### Review`, replace that review in place (same position). Never add a second one.

## 2. Score: 5 dimensions × 0–2 = /10

**A. Phase timing** (targets: select 0–4, connect 4–9, run 9–16, rehearse 16–20).
A phase counts as **recorded** only when both of its boundaries come from a timestamp in the files:
- select: drill start → the first `use.sh` event in `drills/events.log` inside the window
- connect: that `use.sh` event → the report's first timestamp (filename `YYYYmmdd-HHMM`, or its timing table)
- run: the report's first timestamp → the report's mtime
- rehearse: the report's mtime → drill end, and only if the entry's status is `completed`
Give a table: phase | target min | actual min (or "not recorded") | over/under.
Scoring, applied in this order:
- **0** if fewer than 2 phases are recorded, if the drill was aborted, or if any recorded phase is more than 2 minutes over target.
- **At most 1** if any of the 4 phases is not recorded.
- **Rehearse is a minimum, not a maximum:** select, connect and run pass when they're under target. Rehearse passes only if it lasted at least 2 minutes. A shorter rehearse counts as not within target, so A is at most 1.
- **2** only if all 4 are recorded and each is within its target.
- Otherwise 1.

**B. Tool calls.** Take them from the report's timing table and compare with the cap of 6 per use case and 18 in total. Score 2 for 12 or fewer within the cap, 1 for within the cap, 0 for over the cap or no table.

**C. Selection criteria stated.** Score this from `drills/log.md` (the entry's "server picked", "notes" and "what broke" fields) or `drills/events.log` only. Neither the report nor your own judgment counts. **Fit cap:** if the entry's "what broke" says "chose X over ★ Y", or the report itself says the server is a poor fit for the topic, C scores at most 1 however many criteria were stated, and fix 1 must be about selection. Score 2 if at least 3 named criteria are recorded (e.g. official/maintained/transport-auth/read-only/rate limits/license/fit) or a `/pick-server` run is recorded with its winner. Score 1 if 1 or 2 criteria are recorded. **Score 0 if neither file shows criteria were stated**, even when a server was picked.

**D. Use-case structure.** Check each UC for Persona → Question → Finding with a source ID (accession number, CVE ID, arXiv ID, patent number, repo full_name, HF repo ID or URL) → Why it matters. Give a table UC1 to UC3 with ✓ or ✗ per element and the word count (cap 120). Score 2 if every cell is ✓, 1 for one or two gaps, 0 for more.

**E. Provenance & math.** Re-check 2 percentages from the report's shown arithmetic yourself. Check that ⚠ flags exist where the report mentions server-computed figures, that every finding has a source ID or an `[outside knowledge]` label, and that a Sources list exists and matches the IDs used. Also count as one issue: any "Why it matters" claim not supported by that use case's cited findings and not labeled `[inference]`. Also count as one issue: findings that rest only on third-party sources (blogs, news) when the session left call budget and a primary source (vendor page, filing, official API) was reachable through a loaded server. Score 2 if clean, 1 for one issue, 0 for more. List each issue.

## 3. Three fixes
Write the 3 highest-impact, concrete fixes for the next drill, lowest-scoring dimension first. Each is one line: what to do differently, and which file or command.

## 4. Write the review under the latest entry in drills/log.md
Use Edit to insert this immediately after the latest entry's last line (before any following `## `), or to replace that entry's existing review:
```
### Review (<date>): <score>/10
| Dim | Score | Evidence |
(A–E, one line each)
Phase timing: <compact table or "not recorded">
Fixes:
1. …
2. …
3. …
```

## 5. Print exactly 4 lines, nothing else
1. `Drill: <topic> (<type>), <score>/10, trend <trend>`
2. `Phases: select <a>m, connect <b>m, run <c>m, rehearse <d>m` (use "n/r" for not recorded)
3. `Use cases: <x>/3 complete, <n> tool calls, provenance <ok | n issues>`
4. `Top fix: <fix 1>`
