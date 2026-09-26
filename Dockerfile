# ==============================================================================
# Multi-stage Dockerfile for Delphix DCT MCP Server (Pure Upstream)
# ==============================================================================
FROM python:3.11-slim AS builder

WORKDIR /build

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    git \
    && rm -rf /var/lib/apt/lists/*

# Delphix MCP Server version / tag to install from upstream
ARG MCP_TAG=2026.0.3.0-Preview

RUN pip install --no-cache-dir --prefix=/install "git+https://github.com/delphix/dxi-mcp-server.git@${MCP_TAG}"

# ==============================================================================
# Final Runtime Stage
# ==============================================================================
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies and CA certificates
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy installed Python packages from builder stage
COPY --from=builder /install /usr/local

# Copy Delphix CA certificate and update system CA store
COPY delphix_ca.crt /usr/local/share/ca-certificates/delphix_ca.crt
RUN update-ca-certificates

# Configure SSL certificate bundle for Python requests / httpx
ENV REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
ENV PYTHONUNBUFFERED=1

# Run as non-root user
RUN groupadd -g 1000 mcpuser && \
    useradd -u 1000 -g mcpuser -s /bin/false -m mcpuser && \
    mkdir -p /app/logs && chown -R mcpuser:mcpuser /app

USER mcpuser

# Default entrypoint runs the MCP server over stdio
ENTRYPOINT ["dct-mcp-server"]
