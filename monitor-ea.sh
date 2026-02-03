#!/bin/bash
# Servidor web simple para monitoreo

while true; do
    echo -e "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\n" > response
    
    echo "=== CRT EVOLUTION STATUS ===" >> response
    echo "Time GMT: $(date -u '+%Y-%m-%d %H:%M:%S')" >> response
    echo "Time NY: $(TZ=America/New_York date '+%Y-%m-%d %H:%M:%S')" >> response
    echo "" >> response
    
    # Verificar MT5
    if pgrep -f terminal.exe > /dev/null; then
        echo "🟢 MT5: RUNNING" >> response
        echo "PID: $(pgrep -f terminal.exe)" >> response
    else
        echo "🔴 MT5: STOPPED" >> response
    fi
    
    # Verificar horario
    hora_gmt=$(date -u +"%H")
    if [ $hora_gmt -ge 8 ] && [ $hora_gmt -lt 22 ]; then
        echo "🟢 TRADING: ACTIVE (3AM-5PM NY)" >> response
    else
        echo "⏸️ TRADING: INACTIVE" >> response
    fi
    
    echo "" >> response
    echo "=== ENDPOINTS ===" >> response
    echo "/status - This page" >> response
    echo "/health - Health check" >> response
    
    cat response | nc -l -p 8080 -q 1
    sleep 1
done
