FROM python:3.11-slim

# Install tools + supervisor
RUN apt-get update && \
    apt-get install -y \
        supervisor \
        curl \
        iproute2 \
        net-tools \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
COPY wrapper.py .
COPY supervisor.conf /etc/supervisor/conf.d/supervisor.conf
COPY run_mcp.sh /app/run_mcp.sh
RUN chmod +x /app/run_mcp.sh

COPY src/ ./src/

# Install Python deps
RUN pip install --no-cache-dir -r requirements.txt

ENV PYTHONPATH="/app/src"

EXPOSE 8000

# Create FIFO + output file (NOT FIFO)
ENTRYPOINT ["/bin/sh", "-c", "\
    if [ ! -p /tmp/mcp_in ]; then mkfifo /tmp/mcp_in; fi && \
    if [ ! -f /tmp/mcp_out ]; then touch /tmp/mcp_out; fi && \
    chmod 666 /tmp/mcp_in /tmp/mcp_out && \
    exec supervisord -n \
"]
