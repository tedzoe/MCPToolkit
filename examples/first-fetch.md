# First Fetch example

This is an example of the keyless smoke test, not a market-research finding.

```bash
servers/preflight.sh --live fetch
```

Expected output includes a line shaped like:

```text
fetch              PASS       tools=1    fetch -> Contents of https://example.com/: ...
PASS preflight
```

The test lists Fetch's tools and calls `fetch(url="https://example.com", max_length=300)`. The page describes itself as a domain for documentation examples. Source: [Example Domain](https://example.com/). Exact wording and tool counts can change with the pinned server or page.

For a research report, `/usecases <topic> <server>` plans three decisions, makes at most six MCP calls per use case, checks arithmetic and adds source IDs. It writes the result to the ignored `outputs/` directory. See `.claude/commands/usecases.md` for the complete format. Do not invent a sample finding or call it live-verified without performing the cited calls.
