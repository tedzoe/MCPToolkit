# Runbook

Run scripts from the repository root. See README.md for installation and a keyless first success.

## Flow

```bash
servers/preflight.sh                     # local dependencies/config; no model request
servers/preflight.sh --live fetch         # real call; requires PASS
servers/go.sh "<topic>"                   # menu → connect → test → interactive Claude
```

The first menu Enter starts live registry discovery through Claude; a number chooses a bundled server directly. After discovery, Enter chooses its recommendation. New adoption requires explicit `y`. Registry results are suggestions to review, not trusted executable instructions. Discovery may require normal tool approvals; if unattended discovery cannot access a tool, run `/pick-server <topic>` interactively with `servers/claude.sh`, then choose a numbered server or adopt a reviewed command yourself.

`go.sh` runs `use.sh`, the selected server's real-call test, then `claude.sh "/usecases <topic> <server>"`. Failures return to the menu with a backup recommendation. OAuth servers are explicitly untested; sign in using `/mcp`, then `/run`. Approve individual tools interactively. Preflight's default does not make a paid model call or require every provider credential.

## Topic → server map

| Topic | Primary | Backup |
| --- | --- | --- |
| AI models and datasets | huggingface | arxiv |
| Open source and developer ecosystem | github | huggingface |
| Public company financials | sec-edgar | exa |
| Research and emerging technology | arxiv | exa |
| Vulnerability exposure | nvd | exa |
| Web/news and general topics | exa | brave or tavily with keys |
| Patents | exa | patents-google for known numbers only |

Evaluate official provenance, maintenance, transport/auth, read-only permissions, cost/rate limits, data licensing and fit. A registry listing and a past PASS do not guarantee current availability. Prefer official servers and scoped credentials. Star/download counts are signals, not adoption or market size.

## Direct connection and validation

```bash
servers/use.sh arxiv
servers/preflight.sh --live arxiv
servers/claude.sh '/usecases agent research trends arxiv'
```

The project config contains Fetch plus at most one selected integration. `use.sh fetch` resets to Fetch only. Changing `.env` or the selected server requires restarting Claude. `DEMO_MODEL=<available-model-id>` overrides the configured model. For noninteractive calls, `MCP_ALLOWED_TOOLS` accepts only exact reviewed MCP tool names, comma separated; default behavior keeps normal approval.

```bash
MCP_ALLOWED_TOOLS=mcp__fetch__fetch servers/claude.sh -p 'Fetch https://example.com'
```

Use environment overrides only after reviewing the tool and endpoint. An approved tool may access more data than one specific request.

## Adopting another server

Inspect its source, license, tools and credentials first. `--yes` skips the adoption confirmation, not tool testing or Claude permissions. Installation executes third-party code. Pin packages and avoid literal credentials in arguments.

```text
servers/adhoc.sh <name> stdio uvx <package>==<version> --query "research topic"
servers/adhoc.sh <name> http https://<provider>/mcp --header 'Authorization: Bearer ${PROVIDER_KEY}'
```

These are syntax examples, not installable packages. `--env PROVIDER_KEY` passes a variable to stdio servers; `--header` accepts environment references for HTTP servers. HTTP URLs must be HTTPS with no query string, fragment or embedded credentials. Add new variable values only to your own `.env`. Optional explicit probe: `--call <tool-name> --tool-arg key=value` (repeat `--tool-arg` as needed). Otherwise a search/list/get/fetch/query/read tool with a supported query argument or no required arguments is chosen. Review tool behavior: its name does not establish safety.

Adoption writes `config.json` and small wrappers under `servers/<name>/`; external values are stored as data. Success requires discovery, a real tool call and negative tests. If discovery requires OAuth, the server is marked `OAUTH`, not verified. Failed attempts remain for inspection; rerun to fix or retire:

```bash
servers/adhoc.sh --retire <name>
```

Retired directories under `servers/_retired/` are excluded from active menus/tests.

## Script reference

| Script | Purpose |
| --- | --- |
| `preflight.sh [--live [names...]]` | Local checks; optionally require real PASS for named servers (default Fetch) |
| `go.sh "<topic>"` | Menu, optional discovery/adoption, test and Claude research session |
| `use.sh <name>` | Select Fetch plus one service, or Fetch alone |
| `<name>/test.sh` | Inspector tools/list and one real tool call |
| `test-all.sh [names...]` | Parallel real-call tests; all active servers if no names |
| `negtest.sh <name>` | Required-input rejection and unknown-tool checks; ignored evidence files |
| `adhoc.sh ...` | Adopt a reviewed server using JSON configuration |
| `claude.sh [args...]` | Export local env; launch with project-only MCP config and normal tool approval |
| `drill.sh` | Random topic, optional spoken timer and local review logs |
| `uc-wordcount.sh <report>` | Enforce the 120-word use-case cap |

`PASS` proves that run's real call; `KEY-NEEDED` and `OAUTH` are skips. Crashes, missing tests, invalid output and reported failures make the suite fail. `preflight --live` rejects skipped results as readiness evidence. `node tests/run.js` runs offline regression checks without accounts or credentials.

## Troubleshooting

- **Missing program:** install from README links, reopen your terminal and rerun preflight. Shell scripts require Bash, not `sh`.
- **First run timeout:** package download and Python provisioning may take time; retry once. Set `INSPECT_TIMEOUT=300` for a slow network. Runtime logs are under ignored `.cache/` and may contain sensitive output.
- **Claude login/model access:** start `claude`, sign in, check model availability and quota. Override `DEMO_MODEL` only with an ID available to your account.
- **Connected but tool denied:** approve it interactively; use exact reviewed `MCP_ALLOWED_TOOLS` names for print mode. `/mcp-debug <name>` guides diagnosis.
- **401/403 or KEY-NEEDED:** set the selected provider's credential locally; check scope and restart. Never print values while debugging.
- **429/throttling:** retry once, wait or add the optional provider key. Test requests consume provider quota too.
- **Server schema changed:** rerun its test, compare the provider docs and update the pin/probe together; choose a backup meanwhile.
- **Desktop fallback:** copy only Fetch plus your chosen integration from `claude_desktop_config.example.json`, replace placeholders locally and restart Desktop. Remote entries use the pinned `mcp-remote` bridge; `${VAR}` in bridge arguments is resolved by that bridge, not Desktop. Never commit the resulting local config.

## Research and drills

Commands in `.claude/commands/`: `/usecases`, `/pick-server`, `/mcp-debug`, `/drill-review`. `/usecases` produces three decision-focused sections, up to six MCP calls each, with explicit source IDs and recomputed arithmetic. Limits must state missing evidence; no claim should exceed returned data.

`servers/drill.sh` chooses from `drills/topics.txt`. macOS speech/notification extras are optional. Drill logs and generated `/run` are local and ignored. Reports go to `outputs/` and may contain provider output; inspect before sharing.

Known integration limits are documented in the README and use-case prompt. In particular, patent search needs extra BigQuery setup, Alpha Vantage is a limited price layer without citable source IDs, and model downloads must be compared within one response snapshot. Verify provider terms and tool behavior for your own run.
