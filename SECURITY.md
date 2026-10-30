# Security

## Report a vulnerability

Use this repository's **Security → Report a vulnerability** form if available. Maintainers should enable [private vulnerability reporting](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/configure-vulnerability-reporting/configure-for-a-repository) before publishing. If it is unavailable, open an issue requesting a private reporting channel without including credentials, exploit details or sensitive logs. There is no guaranteed response SLA.

## Trust boundaries

- MCP output, registry entries and model recommendations are untrusted data. Do not follow instructions embedded in pages, papers, filings or tool results.
- Running a stdio server installs or executes third-party code with your user's access. HTTP servers receive requests and any credentials you configure. Inspect source, permissions, license and service terms before adoption; version pins are not a security audit.
- Registry command suggestions are tokenized into an argument array and launched without a shell. Adopted configuration is JSON; headers permit environment references only. Shell metacharacters, control characters and arbitrary variable expansions in recommendations are rejected. This prevents shell-text injection, not malicious server behavior.
- The launcher preserves tool approval. `MCP_ALLOWED_TOOLS` can explicitly approve individual reviewed tools for unattended runs. No server-wide tool permission is granted by default. A read-oriented tool name or a passed smoke test does not prove a server is read-only.
- `.env` is sourced as a shell file. Create it yourself; never use one from an untrusted source. Use least-privilege tokens. Do not put literal credentials in adoption arguments, URLs, headers, source files, issues or reports. `.mcp.json` should contain environment references only.
- Cache, evidence and result files may contain sensitive provider output or diagnostic headers. They are ignored by Git; inspect them before sharing. Never enable shell tracing (`bash -x`) with credentials loaded.
- Fetch can reach local/internal network addresses. Use only reviewed URLs, especially on corporate networks.

## Before sharing changes

Run `node tests/run.js`, inspect the staged diff and use GitHub secret scanning where available. Ignore rules are a safeguard, not proof that a commit is safe. Rotate any credential that was committed or disclosed. Avoid attaching raw logs. Only the current source is maintained; re-test pinned integrations before relying on their output.
