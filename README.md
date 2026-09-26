# Delphix DCT MCP Server (Container Image)

OCI / Docker / Podman container image for the official [Delphix DCT MCP Server](https://github.com/delphix/dxi-mcp-server).

## Overview

This repository builds the pure container image for the official Delphix Data Control Tower (DCT) MCP Server. It communicates via the standard MCP `stdio` transport, runs as a non-root user, and bundles the Delphix SSL CA certificate into the system certificate store.

The MCP server code is installed dynamically from upstream Delphix via `pip` at build time, ensuring no source code is duplicated.

## Building the Image

Build the container image using Podman or Docker:

```bash
# Build default version (2026.0.3.0-Preview)
podman build -t dct-mcp-server .

# Or build a specific tag / branch
podman build --build-arg MCP_TAG=2026.0.3.0-Preview -t dct-mcp-server .
```

## Running with MCP Clients (STDIO)

The MCP server runs over `stdio`. Use the `-i` (interactive) flag to keep `stdin` open.

### Podman / Docker CLI

```bash
podman run --rm -i \
  -e DCT_API_KEY="your-api-key-here" \
  -e DCT_BASE_URL="https://your-dct-instance.domain.com" \
  -e DCT_VERIFY_SSL="true" \
  -e DCT_TOOLSET="continuous_data_admin" \
  dct-mcp-server
```

### Claude Desktop / Cursor / Antigravity Configuration

```json
{
  "mcpServers": {
    "delphix-dct": {
      "command": "podman",
      "args": [
        "run", "--rm", "-i",
        "-e", "DCT_API_KEY=your-api-key-here",
        "-e", "DCT_BASE_URL=https://your-dct-instance.domain.com",
        "-e", "DCT_VERIFY_SSL=true",
        "-e", "DCT_TOOLSET=continuous_data_admin",
        "dct-mcp-server"
      ]
    }
  }
}
```

## Environment Variables

| Variable | Description | Default |
| :--- | :--- | :--- |
| `DCT_BASE_URL` | Base URL of your Delphix DCT instance | *Required* |
| `DCT_API_KEY` | Delphix DCT API Key | *Required* |
| `DCT_VERIFY_SSL` | Verify SSL certificates (`true` / `false`) | `true` |
| `DCT_TOOLSET` | Toolset persona (`continuous_data_admin`, `self_service`, `dynamic`) | `dynamic` |
| `DCT_LOG_LEVEL` | Log level (`INFO`, `DEBUG`, `WARNING`, `ERROR`) | `INFO` |
