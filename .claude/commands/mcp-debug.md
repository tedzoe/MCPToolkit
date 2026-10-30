---
description: Troubleshoot an MCP server that is not connecting or not returning data
argument-hint: <server-name>
allowed-tools: Bash
---

Server: `$ARGUMENTS`. Work through the steps in order. Report each step as OK or BROKEN with the evidence line. Stop at the first root cause, fix it, and re-test.

1. **Registered?** `claude mcp list` and `claude mcp get $ARGUMENTS`. Missing: `servers/use.sh $ARGUMENTS`. "Pending approval" in `claude mcp list` is expected: `servers/claude.sh` loads `.mcp.json` with `--mcp-config --strict-mcp-config`, which needs no approval. Check `/mcp` inside Claude instead.
1b. **Calls denied?** Tool approval is separate from connection. Launch interactively with `servers/claude.sh` and approve the specific reviewed tool. For print mode, set `MCP_ALLOWED_TOOLS` to exact names such as `mcp__fetch__fetch`; never bypass all permissions. The launcher does not automatically allow every server tool.
2. **Server alone, outside Claude:** `servers/$ARGUMENTS/test.sh`. PASS here but broken in Claude means a config or env problem, not a server problem. FAIL here means the server or network.
3. **Env vars:** `.mcp.json` holds `${VAR}` refs and Claude expands them at launch. Was Claude started with `servers/claude.sh`? Check that the var is set without printing it: `bash -c 'set -a; . ./.env; [ -n "$VAR" ] && echo set || echo MISSING'`. Changing `.env` requires a Claude restart.
4. **Transport:** stdio (command) vs http (URL). Check `claude mcp get`. Common faults: SSE configured for a streamable-http endpoint, or a missing `/mcp` path suffix. Inspector quirk: it swallows `npx -y` and `-p`. Use `npm_config_yes=true` or a wrapper script.
5. **Runtime:** `node -v`, `uvx --version`. An engine error like "X is not a function" means Node is too old. See `servers/nvd/run.sh` for the per-server node@24 trick. First uvx/npx run downloads packages, so re-run once before you call it a failure.
6. **Auth & limits:** 401/403 means a bad or expired key or the wrong header name. 429 or "rate limit" means the anonymous pool, so add the key from `.env.example`. Check the vendor status page.
7. **Debug log:** `servers/claude.sh --debug` (or `--mcp-debug`), then `/mcp` inside Claude. Look for the server's spawn command, stderr and handshake errors.
8. **Fallback:** if it's not fixed in 3 minutes, switch to the backup server for the topic (see the RUNBOOK backup map): `servers/use.sh <backup>`. Say out loud why. Falling back is part of the demo.
