#!/bin/sh
echo "[MCP Wrapper] MCP server starting..."

[ -p /tmp/mcp_in ] || mkfifo /tmp/mcp_in
[ -f /tmp/mcp_out ] || touch /tmp/mcp_out

# Load environment from .env if not set (fallback)
if ([ -z "$DCT_API_KEY" ] || [ -z "$DCT_BASE_URL" ]) && [ -f .env ]; then
    echo "[MCP Wrapper] Loading environment variables from .env"
    set -a
    . ./.env
    set +a
fi

while true; do
    python3 -u -m dct_mcp_server.main < /tmp/mcp_in > /tmp/mcp_out
done
