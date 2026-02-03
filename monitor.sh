#!/bin/bash
# Servidor web simple para monitoreo CRT Evolution

echo "Servidor monitor iniciado..."

while true; do
    {
        echo -e "HTTP/1.1 200 OK\r\n"
        echo -e "Content-Type: text/plain\r\n\r\n"
        
        echo "=== CRT EVOLUTION STATUS ==="
        echo "Time: $(date)"
        echo "Hora NY: $(TZ=America/New_York date '+%Y-%m-%d %H:%M:%S')"
        echo ""
        
        # Verificar si MT5 está corriendo
        if pgrep -f terminal.exe > /dev/null 2>&1; then
            echo "🟢 MT5: RUNNING"
            echo "PID: $(pgrep -f terminal.exe)"
        else
            echo "🔴 MT5: STOPPED"
        fi
        
        # Verificar horario de trading
        HORA_GMT=$(date -u +"%H")
        if [ $HORA_GMT -ge 8 ] && [ $HORA_GMT -lt 22 ]; then
            echo "🟢 TRADING: ACTIVE (3AM-5PM NY Time)"
        else
            echo "⏸️ TRADING: INACTIVE"
            echo "Próximo trading: 3:00 AM NY (8:00 GMT)"
        fi
        
        echo ""
        echo "=== ENDPOINTS ==="
        echo "/status - Esta página"
        echo "/health - Health check simple"
        
        # Verificar si hay logs
        LOG_FILE="/home/trader/.wine/drive_c/Program Files/MetaTrader 5/MQL5/Files/CRT_Evolution_Log.txt"
        if [ -f "$LOG_FILE" ]; then
            echo ""
            echo "=== ÚLTIMOS LOGS ==="
            tail -5 "$LOG_FILE" 2>/dev/null | head -3
        fi
        
    } | nc -l -p 8080 -q 1 2>/dev/null
    
    sleep 1
done
