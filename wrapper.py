import json
import uuid
import time
import threading
import os
from fastapi import FastAPI
from fastapi.responses import JSONResponse

FIFO_IN = "/tmp/mcp_in"
FIFO_OUT = "/tmp/mcp_out"

app = FastAPI()

response_buffer = []
buffer_lock = threading.Lock()



# Global handle for the MCP input pipe
mcp_stdin = None

@app.on_event("startup")
def start_fifo_manager():
    # 1. Start Reader Thread
    def reader():
        while not os.path.exists(FIFO_OUT):
            time.sleep(0.1)

        with open(FIFO_OUT, "r") as f:
            f.seek(0, 2)  # Tail -f
            while True:
                line = f.readline()
                if not line:
                    if os.path.exists(FIFO_OUT):
                         if os.stat(FIFO_OUT).st_size < f.tell():
                             f.seek(0)
                    time.sleep(0.05)
                    continue

                if not line.endswith("\n"):
                    f.seek(f.tell() - len(line))
                    time.sleep(0.05)
                    continue

                line = line.strip()
                if not line:
                    continue

                try:
                    obj = json.loads(line)
                    with buffer_lock:
                        response_buffer.append(obj)
                except:
                    continue

    thread = threading.Thread(target=reader, daemon=True)
    thread.start()

    # 2. Open Persistent Writer
    global mcp_stdin
    # Retry loop to ensure the FIFO exists and reader (server) is ready
    while not os.path.exists(FIFO_IN):
        time.sleep(0.1)
    
    # Open in line-buffered mode or unbuffered to ensure immediate flush
    # buffers=1 means line buffered in text mode
    try:
        mcp_stdin = open(FIFO_IN, "w", buffering=1)
    except Exception as e:
        print(f"Error opening FIFO_IN: {e}")

@app.on_event("shutdown")
def close_fifo_writer():
    global mcp_stdin
    if mcp_stdin:
        mcp_stdin.close()

@app.get("/health")
def health():
    return {"status": "ok"}


def wait_for_response(target_id, timeout=10):
    start = time.time()
    while time.time() - start < timeout:
        with buffer_lock:
            for r in response_buffer:
                if r.get("id") == target_id:
                    response_buffer.remove(r)
                    return r
        time.sleep(0.05)
    return {"error": "Timeout waiting for MCP response", "id": target_id}


@app.post("/mcp")
def mcp_bridge(payload: dict):
    if "id" not in payload:
        payload["id"] = str(uuid.uuid4())

    msg = json.dumps(payload) + "\n"
    
    if mcp_stdin:
        try:
            mcp_stdin.write(msg)
            # Flush handled by buffering=1 (line buffered) but explicit flush is safer
            mcp_stdin.flush()
        except BrokenPipeError:
            # Handle server crash/restart scenario
            return JSONResponse(content={"error": "MCP Server connection lost (Broken Pipe)", "id": payload["id"]}, status_code=500)
    else:
         return JSONResponse(content={"error": "MCP Input Pipe not initialized", "id": payload["id"]}, status_code=500)

    return JSONResponse(content=wait_for_response(payload["id"]))
