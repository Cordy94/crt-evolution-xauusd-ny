#!/bin/bash

echo "╔══════════════════════════════════════════════╗"
echo "║   CRT EVOLUTION - XAUUSD M15 - RENDER        ║"
echo "║   INICIO: $(date)                            ║"
echo "╚══════════════════════════════════════════════╝"

# Configurar variables
export MT5_LOGIN="${MT5_LOGIN}"
export MT5_PASSWORD="${MT5_PASSWORD}"
export MT5_SERVER="${MT5_SERVER}"
export EA_NAME="CRT_Evolution_SNIPER_V7_2.ex5"
export SYMBOL="XAUUSD"
export TIMEFRAME="15"

# Configurar DISPLAY virtual para Wine
echo "🔧 Configurando X virtual framebuffer..."
export DISPLAY=:99
Xvfb :99 -screen 0 1024x768x16 &
sleep 3

# Verificar que Xvfb está corriendo
if ! pgrep Xvfb > /dev/null; then
    echo "⚠️  Xvfb no inició, intentando alternativa..."
    Xvfb :99 &
    sleep 2
fi

echo "✅ Xvfb configurado en DISPLAY=$DISPLAY"

# Función para logs
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> /home/trader/startup.log
}

# Función para notificaciones Telegram
notify() {
    if [ ! -z "$TELEGRAM_BOT_TOKEN" ] && [ ! -z "$TELEGRAM_CHAT_ID" ]; then
        curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
            -d "chat_id=${TELEGRAM_CHAT_ID}" \
            -d "text=CRT_EVOLUTION: $1" \
            > /dev/null
    fi
}

log "=== INICIANDO SISTEMA EN RENDER ==="

# Crear estructura de directorios
mkdir -p "/home/trader/.wine/drive_c/Program Files/MetaTrader 5/MQL5/Experts"
mkdir -p "/home/trader/.wine/drive_c/Program Files/MetaTrader 5/MQL5/Profiles/default"
mkdir -p "/home/trader/.wine/drive_c/Program Files/MetaTrader 5/MQL5/Files"

# Copiar EA si existe
if [ -f "/home/trader/$EA_NAME" ]; then
    cp "/home/trader/$EA_NAME" "/home/trader/.wine/drive_c/Program Files/MetaTrader 5/MQL5/Experts/"
    log "✅ EA copiado a MQL5/Experts/"
else
    log "⚠️  No se encontró el archivo $EA_NAME"
    ls -la /home/trader/
fi

# Crear archivo de configuración MT5
MT5_PATH="/home/trader/.wine/drive_c/Program Files/MetaTrader 5"
cat > "$MT5_PATH/config.ini" << EOF
[Common]
Login=${MT5_LOGIN}
Password=${MT5_PASSWORD}
Server=${MT5_SERVER}
Expert=${EA_NAME}
ExpertParameters=ea.set
Symbol=${SYMBOL}
Period=${TIMEFRAME}
Model=0
EnableReports=1
EnableDDE=0
EnableNews=0
EnableMail=0
EnableSound=0

[Tester]
Expert=${EA_NAME}
ExpertParameters=ea.set
Symbol=${SYMBOL}
Period=${TIMEFRAME}
Model=0

[Charts]
Enable=0
Height=0
Width=0

[Terminal]
ShowLog=0
ShowJournal=0
ShowExperts=0
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

log "📁 Configuración MT5 creada"

# Iniciar servidor web simple para monitoreo
log "🌐 Iniciando servidor web de monitoreo en puerto 8080..."
/home/trader/monitor-ea.sh &
sleep 2

# Instalar MT5 si no existe
if [ ! -f "$MT5_PATH/terminal.exe" ]; then
    log "📦 Descargando MT5..."
    cd "$MT5_PATH"
    wget -q -O mt5setup.exe https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe
    
    log "⚙️ Instalando MT5 en modo silencioso..."
    # Instalar MT5 sin interfaz
    wine mt5setup.exe /S 2>&1 | grep -v "err:winediag" | grep -v "fixme:" &
    MT5_PID=$!
    
    # Esperar instalación
    sleep 30
    
    # Verificar si se instaló
    if [ -f "terminal.exe" ]; then
        log "✅ MT5 instalado correctamente"
    else
        log "⚠️  MT5 puede no haberse instalado completamente, verificando..."
        # Intentar manualmente
        wine mt5setup.exe /S &
        sleep 20
    fi
else
    log "✅ MT5 ya instalado"
fi

# Esperar configuración
sleep 5

# Configurar MT5 para modo consola
log "🛠️ Configurando MT5 para modo consola..."
cat > "$MT5_PATH/config/common.ini" << EOF
[Common]
Language=en
Country=United States
Sounds=0
Charts=0
News=0
Mail=0
EOF

# Iniciar MT5 en modo consola
log "🚀 Iniciando MT5 con EA..."
cd "$MT5_PATH"
wine terminal.exe /config:config.ini /skipupdate /noconsole 2>&1 | grep -v "fixme:" | grep -v "err:winediag" &
MT5_PID=$!

log "⏱️ Esperando que MT5 inicie..."
sleep 15

# Verificar si MT5 está corriendo
if ps -p $MT5_PID > /dev/null; then
    log "✅ MT5 iniciado correctamente (PID: $MT5_PID)"
    notify "✅ CRT Evolution iniciado en Render - XAUUSD M15"
else
    log "⚠️  MT5 no se inició, intentando alternativa..."
    # Intentar sin parámetros
    wine terminal.exe 2>&1 | grep -v "fixme:" &
    sleep 10
fi

# Mantener el contenedor vivo
log "👁️ Sistema en ejecución. Monitoreando..."
notify "🟢 Sistema operativo en Render"

# Bucle principal de monitoreo
while true; do
    # Verificar si MT5 sigue corriendo
    if ! pgrep -f terminal.exe > /dev/null 2>&1; then
        log "⚠️  MT5 se detuvo, reiniciando..."
        cd "$MT5_PATH"
        wine terminal.exe /config:config.ini 2>&1 | grep -v "fixme:" &
        notify "🔄 MT5 reiniciado en Render"
        sleep 10
    fi
    
    # Monitorear horario
    hora_gmt=$(date -u +"%H")
    hora_ny=$(TZ=America/New_York date +"%H:%M")
    
    if [ $hora_gmt -ge 8 ] && [ $hora_gmt -lt 22 ]; then
        if [ $(date +%M) == "00" ]; then
            log "🟢 Trading ACTIVO - Hora NY: $hora_ny"
        fi
    else
        if [ $(date +%M) == "00" ]; then
            log "⏸️ Fuera de horario - Hora NY: $hora_ny"
        fi
    fi
    
    # Mantener el contenedor respondiendo
    echo "." > /dev/null
    
    sleep 60
done
