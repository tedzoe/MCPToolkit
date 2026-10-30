# Publishing checklist

The source can be prepared locally without choosing a public account. Publishing reveals the repository owner's username and commit attribution; use an account and GitHub-provided noreply email appropriate for the desired privacy level. This document contains no owner-specific URL.

1. Run `node tests/run.js`, `servers/preflight.sh --live fetch` and `servers/negtest.sh fetch` from a clean copy. Test other services you plan to advertise with your own credentials. Do not claim skipped services were verified.
2. Review `git status --short`, then stage the intended public files and review `git diff --cached`. Confirm no local handoffs, credential files, results, cache, generated commands or identifying paths are staged. The offline suite checks Git's candidate public files as well as tracked files. Reset `.mcp.json` to its generic Fetch-only form if you switched services locally.
3. Verify your Git author name/email before committing. Make the first commit only with the identity you intend to disclose.
4. Create the GitHub repository under the chosen account, attach its remote and push. Repository name suggestion: `mcp-toolkit`. Description: **Discover, connect and test public MCP servers with Claude Code, then produce sourced research.**
5. Add topics: `mcp`, `model-context-protocol`, `claude-code`, `mcp-server`, `research-tools`, `market-intelligence`. Point the About website at the README or project documentation once a public URL exists.
6. Enable Actions, private vulnerability reporting, and available secret-scanning/push-protection features. Protect the default branch as appropriate. Avoid publishing identifying workflow logs or private issue attachments.
7. Confirm the checks pass on GitHub, follow the README from a fresh clone, and create a release with the tested runtimes and service results. Pin a known working release for demos; remote services can change independently.

Do not publish test credentials, raw reports or real contact details as sample content. The SEC integration requires each user's own contact locally; the repository retains only a placeholder. MIT covers this toolkit, not third-party packages, provider APIs or retrieved datasets.
