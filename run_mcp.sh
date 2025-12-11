#!/bin/sh
echo "[MCP Wrapper] MCP server starting..."

[ -p /tmp/mcp_in ] || mkfifo /tmp/mcp_in
[ -f /tmp/mcp_out ] || touch /tmp/mcp_out

while true; do
    python3 -u -m dct_mcp_server.main < /tmp/mcp_in > /tmp/mcp_out
done
