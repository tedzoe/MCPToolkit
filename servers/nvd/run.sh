#!/usr/bin/env bash
# Package requires Node >=24 (uses Promise.try). npx fetches node@24 for this
# process only, so the global Node stays untouched. Drop the node@24 -p once system Node is >=24.
exec npx -y -p node@24 -p @cyanheads/nist-nvd-mcp-server@0.3.1 nist-nvd-mcp-server "$@"
