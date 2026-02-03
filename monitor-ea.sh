#!/bin/bash

while true; do
    {
        echo -e "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\n"
        echo "=== CRT EVOLUTION STATUS ==="
        echo "Time: $(date)"
        echo "Hora NY: $(TZ=America/New_York date '+%H:%M')"
        echo ""
        
        if pgrep -f terminal.exe > /dev/null; then
            echo "🟢 MT5: RUNNING"
        else
            echo "🔴 MT5: STOPPED"
        fi
        
        echo ""
        echo "Endpoints: /status /health"
    } | nc -l -p 8080 -q 1
    sleep 1
done
