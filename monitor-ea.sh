#!/bin/bash

while true; do
    {
        echo -e "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\n"
        echo "=== CRT EVOLUTION STATUS ==="
        echo "Time: $(TZ=America/New_York date)"
        echo ""
        
        # Verificar MT5
        if pgrep -f terminal.exe > /dev/null; then
            echo "🟢 MT5: RUNNING"
            echo "PID: $(pgrep -f terminal.exe)"
        else
            echo "🔴 MT5: STOPPED"
        fi
        
        # Verificar horario
        HORA_GMT=$(date -u +"%H")
        if [ $HORA_GMT -ge 8 ] && [ $HORA_GMT -lt 22 ]; then
            echo "🟢 TRADING: ACTIVE (3AM-5PM NY)"
        else
            echo "⏸️ TRADING: INACTIVE"
        fi
        
        echo ""
        echo "Endpoints: /status (this)"
    } | nc -l -p 8080 -q 1 2>/dev/null
    sleep 1
done
