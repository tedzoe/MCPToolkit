---
description: Find, score and recommend an MCP server for a topic (selection criteria out loud)
argument-hint: <topic>   e.g. "cloud cost management"
allowed-tools: Bash(curl:*), Bash(jq:*), Bash(gh:*), Bash(npm view:*), Bash(ls:*), Bash(cat:*), Read
---

Topic: `$ARGUMENTS`

1. **Check pre-verified first.** Run `ls servers/` and read `servers/*/last-result.json` (written by each `test.sh`). If a server here already fits, include it as a candidate. Its PASS status is evidence.
2. **Search the official registry.** Try 2 or 3 keyword variants:
   `curl -s "https://registry.modelcontextprotocol.io/v0.1/servers?search=<kw>&limit=30&version=latest" | jq -r '.servers[].server | "\(.name)\t\(.version)\t\(.repository.url // "-")\t\([.packages[]?.identifier]|join(","))\t\([.remotes[]?.url]|join(","))"' | sort -u`
   Pick the top 3 to 5 distinct candidates. Prefer `io.github.<vendor>` / vendor-domain names.
3. **Verify each candidate live. Do not trust the listing.**
   - Repo: `gh api repos/<owner>/<repo> --jq '"\(.stargazers_count) \(.pushed_at) \(.archived) \(.license.spdx_id)"'`
   - Package exists: `npm view <pkg> version time.modified` or `curl -s https://pypi.org/pypi/<pkg>/json | jq -r .info.version`
   - README: read the auth and env vars, rate limits and the read-only option.
   A registry entry whose package or repo 404s is disqualified. This really happens: a USPTO server is listed but deleted.
4. **Score table** (0 to 2 each, max 14):

| Candidate | Official vendor | Maintained (<6 mo) | Transport/auth (stdio+token > remote+token > OAuth) | Read-only | Keyless / free tier | Data license clear | Fit to topic | Total |

5. **Recommend one**, and name a backup. In 2 sentences per reject, say why it lost (e.g. "unofficial wrapper of the same API", "last commit 2025", "OAuth only, can't script in 20 minutes", "package 404").
6. Your LAST line must be exactly one machine-readable line, plain text, not in a code block. The go.sh menu parses it:
   `NEXT: servers/use.sh <name>` when the winner is pre-verified, or
   `NEXT: servers/adhoc.sh <short-name> stdio|http ...` when it isn't (format below). No other text on that line.
   Details for the adhoc form: Otherwise, give ONE exact adoption line, which the go.sh menu's `a` option takes as pasted:
   `servers/adhoc.sh <short-name> stdio <command> <pinned package and args> [--env VAR]... [--query "<topic keyword>"]`
   or `servers/adhoc.sh <short-name> http <url> [--header 'Name: value ${VAR}']... [--query "<topic keyword>"]`.
   Name keys by .env variable only, never values. For npx, never include `-y`. Use HTTPS endpoints without query strings and keep headers in the form `Name: ${KEY}` or `Authorization: Bearer ${KEY}`. Use `--call TOOL --tool-arg key=value` for explicit calls. Recommendations are parsed as arguments, not evaluated by a shell; do not include escapes, shell syntax, or embedded newlines. If the key isn't in .env yet, say which variable to add. adhoc.sh runs discovery, a real call and the negative tests, and the server joins the menu.
