# MCP Toolkit

A terminal toolkit for discovering, connecting and testing **Model Context Protocol (MCP) servers with Claude Code**. Choose a public data source, verify a real tool call, then produce three short, sourced research use cases: market momentum, competitive comparison and vendor risk.

Includes 12 server integrations, a topic-based menu, MCP Inspector smoke tests, failure-contract checks, and optional timed practice drills. This is a collection of scripts and prompts, not an MCP server or an official vendor product.

## Requirements

- macOS or Linux with Bash 3.2 or newer. Windows users need WSL; native PowerShell is not supported. Spoken drill reminders are optional and macOS-only.
- [Node.js](https://nodejs.org/en/download) 22 or newer, with `npm`/`npx`.
- [uv](https://docs.astral.sh/uv/getting-started/installation/) with `uvx`. uv downloads the required Python runtime if needed.
- `git`, `jq`, `curl`, and Perl. For example, with Homebrew: `brew install node uv jq`; on Ubuntu/Debian: `sudo apt-get install git jq curl perl`, then install Node and uv using the links above.
- [Claude Code](https://code.claude.com/docs/en/setup) and an account with access, for the assistant workflow. Inspector tests work without signing into Claude. Claude usage and some data providers may incur charges.
- Optional: [GitHub CLI](https://cli.github.com/) (`gh auth login`) for repository details during live discovery.

## First success: no API keys

1. Use this repository's **Code → HTTPS** button to copy its clone command and run it, or download and extract the ZIP. Then open a terminal in the project directory:

   ```bash
   cd mcp-toolkit
   ```

2. Check dependencies and run a real Fetch call:

   ```bash
   servers/preflight.sh
   servers/preflight.sh --live fetch
   ```

   Expect `fetch PASS tools=1 ...` and `PASS preflight`. The test lists tools and fetches `https://example.com`. The first run downloads pinned third-party packages and can take several minutes. No `.env` or Claude model request is needed for this test. Dependency check failures name the missing program.

3. To use Claude, run `claude` once and follow its sign-in instructions, then exit. Launch the toolkit session:

   ```bash
   servers/claude.sh 'Use the fetch tool to read https://example.com and summarize it.'
   ```

   Accept the project trust prompt only after reviewing the files. Approve the Fetch tool when prompted. `/mcp` shows connection status. The launcher uses your configured Claude model; to select another available model, set `DEMO_MODEL=<model-id>` before the command.

See [an example of the first result](examples/first-fetch.md).

## Research workflow

```bash
servers/go.sh "open-source developer tools"
```

Choose a server number, or press Enter for live registry discovery. The menu connects and tests the chosen server, then opens Claude on `/usecases`. Review tool permissions when prompted. Reports go into the ignored `outputs/` directory. Live discovery is an assistant request and needs Claude authentication; you can skip it by choosing a numbered server.

For a direct path:

```bash
servers/use.sh arxiv
servers/preflight.sh --live arxiv
servers/claude.sh '/usecases agent research trends arxiv'
```

Fetch remains available alongside at most one selected server. Remote services can change their tools or impose anonymous rate limits; a local test is evidence for that run, not a permanent compatibility guarantee.

## Credentials: only for the services you choose

Fetch needs none. For other services, optionally copy `.env.example` to `.env`, fill in only the needed values and restart the launcher. This is a local shell file: quote values with spaces, never paste executable shell commands, and do not share it. The launcher exports it for `${VAR}` references in MCP configuration.

| Server | Data | Credentials / limits |
| --- | --- | --- |
| `fetch` | Web page content | None |
| `arxiv` | Research papers | None; local paper cache |
| `huggingface` | Models and datasets | Optional `HF_TOKEN` for higher limits |
| `exa` | Web search | Optional `EXA_API_KEY`; anonymous limits vary |
| `nvd` | CVEs | Optional `NVD_API_KEY`; wrapper downloads Node 24 |
| `github` | Public repositories | `GITHUB_PAT`, scoped read-only |
| `sec-edgar` | Public filings | `SEC_EDGAR_USER_AGENT`, your real contact as required by the SEC |
| `brave` | Web and news search | `BRAVE_API_KEY` |
| `tavily` | Web search | `TAVILY_API_KEY` |
| `semantic-scholar` | Research papers | Optional `SEMANTIC_SCHOLAR_API_KEY`; anonymous calls may throttle |
| `patents-google` | Known patent numbers | Lookup only; search requires additional BigQuery setup |
| `alphavantage` | Market prices | `ALPHAVANTAGE_API_KEY`; demo fallback is limited; not suitable as a primary citable source |

Provider sign-up links are in [.env.example](.env.example). Third-party licenses, API terms, charges and data-use restrictions apply separately from this project's MIT license.

## Testing and safety

```bash
node tests/run.js                       # offline regression and public-file checks
servers/test-all.sh fetch arxiv          # real network calls, named services only
servers/negtest.sh fetch                 # invalid-input and unknown-tool checks
```

`test-all.sh` without names tests all integrations and may use your configured credentials/quota. `PASS` means a real call succeeded; `KEY-NEEDED` and `OAUTH` are explicit skips. `preflight.sh --live <name>` requires a real `PASS`. Normal tool approval stays enabled. For a deliberately unattended request, set `MCP_ALLOWED_TOOLS` to exact reviewed tool names, such as `mcp__fetch__fetch`; server-wide wildcards are rejected.

Read [SECURITY.md](SECURITY.md) before adopting additional servers. Registry text is untrusted. Recommendations are parsed into arguments without shell evaluation, but installing a server still runs third-party code. Credentials belong in environment variables, never command arguments or URLs. Adoption stores JSON configuration and requires both real-call and negative tests to pass; OAuth servers are marked untested.

## More

- [Runbook: selection, adoption, troubleshooting and drills](RUNBOOK.md)
- [Contributing and validation](CONTRIBUTING.md)
- [Maintainer publishing checklist](PUBLISHING.md)
- [MIT license](LICENSE)

Search terms: MCP, Model Context Protocol, Claude Code, MCP Inspector, server discovery, public data research, market intelligence.
