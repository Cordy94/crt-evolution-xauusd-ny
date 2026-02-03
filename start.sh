#!/bin/bash

echo "╔══════════════════════════════════════════════╗" > /home/trader/status.txt
echo "║   CRT EVOLUTION - XAUUSD M15 - RENDER        ║" >> /home/trader/status.txt
echo "║   Iniciado: $(date)                          ║" >> /home/trader/status.txt
echo "╚══════════════════════════════════════════════╝" >> /home/trader/status.txt

# Función para logs
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> /home/trader/startup.log
    echo "$1"
}

# Función para notificaciones Telegram
notify() {
    if [ ! -z "$TELEGRAM_BOT_TOKEN" ] && [ ! -z "$TELEGRAM_CHAT_ID" ]; then
        curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
            -d "chat_id=${TELEGRAM_CHAT_ID}" \
            -d "text=CRT_EVOLUTION_RENDER: $1" \
            > /dev/null
    fi
}

log "=== INICIANDO SISTEMA EN RENDER ==="

# Crear estructura de directorios
mkdir -p "/home/trader/.wine/drive_c/Program Files/MetaTrader 5/MQL5/Experts"
mkdir -p "/home/trader/.wine/drive_c/Program Files/MetaTrader 5/MQL5/Profiles/default"
mkdir -p "/home/trader/.wine/drive_c/Program Files/MetaTrader 5/MQL5/Files"

# Copiar EA si existe
EA_NAME="CRT_Evolution_SNIPER_V7_2.ex5"
if [ -f "/home/trader/$EA_NAME" ]; then
    cp "/home/trader/$EA_NAME" "/home/trader/.wine/drive_c/Program Files/MetaTrader 5/MQL5/Experts/"
    log "✅ EA copiado a MQL5/Experts/"
fi

# Crear archivo de configuración
MT5_PATH="/home/trader/.wine/drive_c/Program Files/MetaTrader 5"
cat > "$MT5_PATH/config.ini" << EOF
[Common]
Login=${MT5_LOGIN}
Password=${MT5_PASSWORD}
Server=${MT5_SERVER}
Expert=${EA_NAME}
ExpertParameters=ea.set
Symbol=XAUUSD
Period=15
Model=0
EnableReports=1
EnableDDE=0
EnableNews=0

[Tester]
Expert=${EA_NAME}
ExpertParameters=ea.set
Symbol=XAUUSD
Period=15
Model=0

[Charts]
Enable=0
EOF

# Crear ea.set con parámetros
cat > "$MT5_PATH/MQL5/Profiles/default/ea.set" << EOF
[Parameters]
InitialLot=${EA_INITIAL_LOT:-0.01}
StepDollars=${EA_STEP_DOLLARS:-10.0}
MaxLotLimit=${EA_MAX_LOT:-10.0}
SL_Points=${EA_SL_POINTS:-110}
TP_Multiplier=${EA_TP_MULTIPLIER:-5}
NY_Start_Hour=${EA_NY_START:-8}
NY_End_Hour=${EA_NY_END:-22}
MagicNumber=${EA_MAGIC:-240226}
Comment=CRT_Evolution_Render
EOF

log "📁 Configuración creada"

# Iniciar servidor web simple para monitoreo (en puerto 8080)
log "🌐 Iniciando servidor web de monitoreo en puerto 8080..."
while true; do
    {
        echo -e "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\n"
        /home/trader/monitor-ea.sh
    } | nc -l -p 8080 -q 1
done &

# Iniciar X virtual framebuffer
log "🖥️ Iniciando Xvfb..."
Xvfb :99 -screen 0 1024x768x16 &
export DISPLAY=:99
sleep 2

# Instalar MT5 si no existe
if [ ! -f "$MT5_PATH/terminal.exe" ]; then
    log "📦 Descargando MT5..."
    cd "$MT5_PATH"
    wget -q -O mt5setup.exe https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe
    log "⚙️ Instalando MT5 (esto puede tomar 2-3 minutos)..."
    wine mt5setup.exe /S
    sleep 10
    log "✅ MT5 instalado"
else
    log "✅ MT5 ya instalado"
fi

# Esperar configuración de Wine
sleep 3

log "🚀 Iniciando MT5 con EA..."
cd "$MT5_PATH"
wine terminal.exe /config:config.ini &

notify "✅ CRT Evolution iniciado en Render - XAUUSD M15"

# Mantener el contenedor vivo y monitorear
log "👁️ Entrando en modo monitoreo..."
while true; do
    # Verificar si MT5 sigue corriendo
    if ! pgrep -f terminal.exe > /dev/null; then
        log "⚠️ MT5 se detuvo, reiniciando..."
        cd "$MT5_PATH"
        wine terminal.exe /config:config.ini &
        notify "🔄 MT5 reiniciado en Render"
    fi
    
    # Actualizar estado horario
    hora_gmt=$(date -u +"%H")
    if [ $hora_gmt -ge 8 ] && [ $hora_gmt -lt 22 ]; then
        if [ $(date +%M) == "00" ]; then
            log "🟢 Trading ACTIVO - Hora NY: $(TZ=America/New_York date '+%H:%M')"
        fi
    else
        if [ $(date +%M) == "00" ]; then
            log "⏸️ Fuera de horario - Hora NY: $(TZ=America/New_York date '+%H:%M')"
        fi
    fi
    
    sleep 60
done
