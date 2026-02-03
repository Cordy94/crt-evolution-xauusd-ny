#!/bin/bash
# Monitor para EA - expone logs via HTTP

echo "Content-type: text/plain"
echo ""

LOG_FILE="/home/trader/.wine/drive_c/Program Files/MetaTrader 5/MQL5/Files/CRT_Evolution_Log.txt"
MT5_PATH="/home/trader/.wine/drive_c/Program Files/MetaTrader 5"

case "$REQUEST_URI" in
    /logs)
        if [ -f "$LOG_FILE" ]; then
            tail -50 "$LOG_FILE"
        else
            echo "Esperando logs del EA..."
            echo "Hora servidor: $(date)"
            echo "Hora NY: $(TZ=America/New_York date)"
        fi
        ;;
    /status)
        echo "=== ESTADO CRT EVOLUTION ==="
        echo "Hora GMT: $(date -u '+%Y-%m-%d %H:%M:%S')"
        echo "Hora NY: $(TZ=America/New_York date '+%Y-%m-%d %H:%M:%S')"
        echo ""
        
        # Verificar si MT5 está corriendo
        if pgrep -f terminal.exe > /dev/null; then
            echo "🟢 MT5: EN EJECUCIÓN"
            echo "Proceso ID: $(pgrep -f terminal.exe)"
        else
            echo "🔴 MT5: DETENIDO"
        fi
        
        # Verificar horario de trading
        hora_gmt=$(date -u +"%H")
        if [ $hora_gmt -ge 8 ] && [ $hora_gmt -lt 22 ]; then
            echo "🟢 HORARIO: TRADING ACTIVO (3AM-5PM NY)"
        else
            echo "⏸️ HORARIO: FUERA DE TRADING"
        fi
        
        # Verificar conexión
        echo ""
        echo "=== CONEXIÓN MT5 ==="
        if [ -f "$MT5_PATH/config.ini" ]; then
            grep -E "Login|Server" "$MT5_PATH/config.ini" | head -2
        fi
        ;;
    /restart)
        echo "Reiniciando MT5..."
        pkill -f terminal.exe
        sleep 2
        cd "$MT5_PATH"
        wine terminal.exe /config:config.ini &
        echo "MT5 reiniciado"
        ;;
    *)
        echo "Endpoints disponibles:"
        echo "/logs     - Ver últimos logs"
        echo "/status   - Ver estado del sistema"
        echo "/restart  - Reiniciar MT5"
        ;;
esac
