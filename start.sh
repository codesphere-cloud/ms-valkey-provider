#!/bin/sh

cleanup() {
    printf "\nCaught signal! Shutting down services...\n"

    # Kill the background subshell running the nc loop and Valkey
    kill $HTTP_PID $VALKEY_PID 2>/dev/null

    # Because nc is a child process of the subshell, it might be stuck
    # listening on the port. We explicitly kill it to free port 3000.
    killall nc 2>/dev/null

    # Wait for Valkey to cleanly save and exit
    wait $VALKEY_PID 2>/dev/null

    echo "All services stopped cleanly."
    exit 0
}

trap cleanup INT TERM

echo "Starting nc HTTP server on port 3000..."
# Run the nc server in a backgrounded subshell
(
    while true; do
        printf "HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nOK" | nc -l -p 3000 >/dev/null 2>&1
    done
) &
HTTP_PID=$!

echo "Starting Valkey..."
cd /home/user/app && /usr/local/bin/docker-entrypoint.sh --requirepass $VALKEY_PWD --save 60 1 &
VALKEY_PID=$!

echo "Both services are running in parallel. Press Ctrl+C to stop."

wait