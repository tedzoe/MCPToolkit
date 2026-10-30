# Contributing

Bug reports, reproducible fixes and well-tested public data integrations are welcome. Use an issue to describe the problem, expected behavior, operating system, runtime versions and smallest reproduction. Redact credentials, local usernames and private URLs. Report security issues using SECURITY.md.

## Local checks

```bash
node tests/run.js
servers/preflight.sh --live fetch
servers/negtest.sh fetch
```

The offline suite uses isolated temporary copies and mocks for failure paths; it does not require Claude login or API keys. Live tests download pinned third-party packages and contact public endpoints. For a service-specific change, also run its `test.sh` and `negtest.sh` with your own scoped credentials. Describe skipped checks and external rate limits honestly in the pull request.

Keep shell scripts compatible with Bash 3.2 on macOS and Linux. Keep executable bits on entry points. Store new service configuration as data; never evaluate registry or tool output as shell. Preserve default tool approval and do not broaden permissions for convenience. New integrations need a pinned package where applicable, provider/license links, environment variable names, one small real-call test and documented limits.

Do not commit `.env`, local MCP configurations containing absolute paths or literal secrets, result files, output reports, cache, evidence, drill logs or local handoffs. Include only generic examples. Git commits and GitHub accounts expose attribution publicly; contributors who want privacy should configure an appropriate GitHub-provided noreply address before committing.
