# Delphix DCT MCP Server (Dockerized)

This project provides a Docker container that wraps the Delphix DCT Model Context Protocol (MCP) server, exposing an HTTP interface to facilitate integration with orchestration tools like n8n, which do not natively support `stdio` communication.

## Architecture

The project uses a "Sidecar Wrapper" pattern within the same container:

1.  **HTTP Wrapper (FastAPI)**: Listens for POST requests on port 8000.
2.  **Supervisor**: Manages processes to ensure both (wrapper and MCP server) are always running.
3.  **FIFO Pipes**: Communication between the HTTP wrapper and the MCP server (Python) is handled via named pipes (`mkfifo`) at `/tmp/mcp_in` and `/tmp/mcp_out`.
4.  **Persistence**: The wrapper maintains a persistent connection to the MCP server's `stdin`, allowing for long-lived, authenticated sessions.

## Prerequisites

- Docker or Podman installed on your system.

## Building the Image

To build the image locally, run:

```bash
sudo podman build -t dxi-mcpsrv-docker .
```

(You can replace `podman` with `docker` if that is your preferred runtime).

## Running the Container

The container requires certain environment variables to correctly connect to the Delphix DCT API.

```bash
sudo podman run -d \
  -p 8099:8000 \
  --name dxi-mcpsrv-docker \
  -e DCT_API_KEY="your-api-key-here" \
  -e DCT_BASE_URL="https://your-dct-server.com" \
  -e DCT_VERIFY_SSL="false" \
  -e DCT_LOG_LEVEL="INFO" \
  localhost/dxi-mcpsrv-docker
```

### Environment Variables

| Variable | Description | Default Value |
| :--- | :--- | :--- |
| `DCT_API_KEY` | **Required**. API Key generated in Delphix DCT. | - |
| `DCT_BASE_URL` | **Required**. Base URL of your DCT instance. | - |
| `DCT_VERIFY_SSL` | Validate SSL certificates of the DCT server. | `false` |
| `DCT_LOG_LEVEL` | Log detail level (DEBUG, INFO, ERROR). | `INFO` |

## API Usage

The server exposes a single main endpoint: `POST /mcp`.

### 1. Initialization

**Important:** Before executing any tool, you must send the initialization message to establish the session.

```bash
curl -s -X POST http://localhost:8099/mcp \
  -H "Content-Type: application/json" \
  -d '{
        "jsonrpc":"2.0",
        "id":"init-1",
        "method":"initialize",
        "params":{
          "protocolVersion":"2024-11-05",
          "capabilities":{"tools":{"call":true,"list":true}},
          "clientInfo":{"name":"cli","version":"0.1"}
        }
      }'
```

### 2. Calling Tools

Once initialized, you can invoke the available tools. For example, to use `search_engines`:

```bash
curl -s -X POST http://localhost:8099/mcp \
  -H "Content-Type: application/json" \
  -d '{
        "jsonrpc":"2.0",
        "id":"query-1",
        "method":"tools/call",
        "params":{
          "name":"search_engines",
          "arguments":{"limit":5}
        }
      }'
```

### n8n Integration

To integrate with n8n, use the **HTTP Request** node:

-   **Method**: POST
-   **URL**: `http://your-docker-host:8099/mcp`
-   **Headers**: `Content-Type: application/json`
-   **Body**: JSON Raw (copy the JSON from the examples above).

We recommend creating a workflow that performs `initialize` at the start (or just once if the container is persistent) and then makes tool calls as needed.

## Troubleshooting

### Container Logs

If you encounter issues, check the container logs to see output from both the wrapper and the internal MCP server:

```bash
sudo podman logs -f dxi-mcpsrv-docker
```

### Connection Reset

If the internal MCP server fails or disconnects, the wrapper will return a 500 error indicating "Broken Pipe". In this case, restarting the container will reset it to a clean state.
