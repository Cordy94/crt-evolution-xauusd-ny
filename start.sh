#!/bin/bash

echo "╔══════════════════════════════════════════════╗"
echo "║   CRT EVOLUTION SNIPER V7.2 - XAUUSD M15    ║"
echo "║   Horario: 3:00 AM - 5:00 PM (NY Time)      ║"
echo "║   Servidor: 8:00 AM - 22:00 PM GMT          ║"
echo "╚══════════════════════════════════════════════╝"

# Configurar variables
export MT5_LOGIN="${MT5_LOGIN}"
export MT5_PASSWORD="${MT5_PASSWORD}"
export MT5_SERVER="${MT5_SERVER}"
export EA_NAME="CRT_Evolution_SNIPER_V7_2.ex5"
export SYMBOL="XAUUSD"
export TIMEFRAME="15"

# Horario convertido: 3AM-5PM NY = 8AM-10PM GMT
export HORA_INICIO=8     # 8:00 GMT = 3:00 AM NY
export HORA_FIN=22       # 22:00 GMT = 5:00 PM NY

# Función para notificaciones
notify() {
    local msg="$1"
    local hora_gmt=$(date -u '+%H:%M')
    local hora_ny=$(date '+%H:%M')
    
    echo "[GMT: $hora_gmt | NY: $hora_ny] $msg"
    
    if [ ! -z "$TELEGRAM_BOT_TOKEN" ] && [ ! -z "$TELEGRAM_CHAT_ID" ]; then
        curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
            -d "chat_id=${TELEGRAM_CHAT_ID}" \
            -d "text=CRT_EVOLUTION ($hora_ny NY): $msg" \
            -d "parse_mode=HTML" \
            > /dev/null
    fi
}

# Función para verificar si es hora de trading
is_trading_time() {
    local current_hour=$(date -u +"%H")
    local current_minute=$(date -u +"%M")
    local total_minutes=$((10#$current_hour * 60 + 10#$current_minute))
    local start_minutes=$((HORA_INICIO * 60))
    local end_minutes=$((HORA_FIN * 60))
    
    if [ $total_minutes -ge $start_minutes ] && [ $total_minutes -le $end_minutes ]; then
        return 0  # Sí es hora de trading
    else
        return 1  # No es hora de trading
    fi
}

# Crear estructura de carpetas MT5
mkdir -p "/home/trader/.wine/drive_c/Program Files/MetaTrader 5/MQL5/Experts"
mkdir -p "/home/trader/.wine/drive_c/Program Files/MetaTrader 5/MQL5/Profiles/default"
mkdir -p "/home/trader/.wine/drive_c/Program Files/MetaTrader 5/config"

# Copiar EA si existe
if [ -f "/home/trader/$EA_NAME" ]; then
    cp "/home/trader/$EA_NAME" "/home/trader/.wine/drive_c/Program Files/MetaTrader 5/MQL5/Experts/"
    echo "✅ EA copiado a MQL5/Experts/"
fi

# Crear archivo de parámetros del EA (ea.set)
cat > "/home/trader/.wine/drive_c/Program Files/MetaTrader 5/MQL5/Profiles/default/ea.set" << EOF
[Parameters]
InitialLot=${EA_INITIAL_LOT:-0.01}
StepDollars=${EA_STEP_DOLLARS:-10.0}
MaxLotLimit=${EA_MAX_LOT:-10.0}
SL_Points=${EA_SL_POINTS:-110}
TP_Multiplier=${EA_TP_MULTIPLIER:-5}
NY_Start_Hour=${EA_NY_START:-8}      # 8:00 GMT = 3:00 AM NY
NY_End_Hour=${EA_NY_END:-22}         # 22:00 GMT = 5:00 PM NY
MagicNumber=${EA_MAGIC:-240226}
Comment=CRT_Evolution_XAUUSD_M15_LDN_NY
EOF

# Crear config.ini para MT5
cat > "/home/trader/.wine/drive_c/Program Files/MetaTrader 5/config.ini" << EOF
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

[Charts]
Height=0
Width=0
Enable=0

[Tester]
Expert=${EA_NAME}
ExpertParameters=ea.set
Symbol=${SYMBOL}
Period=${TIMEFRAME}
Model=0
Optimization=0
ForwardMode=0
ForwardDate=2024.01.01
Deposit=10000
Currency=USD
ProfitInPips=1
EOF

# Crear template para el gráfico
cat > "/home/trader/.wine/drive_c/Program Files/MetaTrader 5/profiles/default.tpl" << EOF
[Charts]
Chart0=1|15|0|1|0|0|11403134|Arial|8|0|0|0|-1
[Chart0]
Height=480
Width=640
Symbol=XAUUSD
Period=15
EOF

notify "🚀 Iniciando sistema CRT Evolution..."

# Iniciar X virtual framebuffer (para Wine)
Xvfb :99 -screen 0 1024x768x16 &
export DISPLAY=:99

# Ruta a MT5
MT5_PATH="/home/trader/.wine/drive_c/Program Files/MetaTrader 5"
cd "$MT5_PATH"

# Instalar MT5 si no existe
if [ ! -f "terminal.exe" ]; then
    notify "📦 Descargando e instalando MT5..."
    wget -q -O mt5setup.exe https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe
    wine mt5setup.exe /S
    sleep 15
    notify "✅ MT5 instalado correctamente"
fi

# Esperar a que Wine esté listo
sleep 5

# Bucle principal
notify "✅ Sistema listo. Monitoreando horario de trading..."

while true; do
    # Obtener hora actual
    current_gmt=$(date -u '+%H:%M')
    current_ny=$(date '+%H:%M')
    
    if is_trading_time; then
        # VERIFICAR SI MT5 ESTÁ CORRIENDO
        if ! pgrep -f terminal.exe > /dev/null; then
            notify "▶️ Iniciando MT5 (Horario de trading activo: $current_ny NY)"
            wine terminal.exe /config:config.ini &
            sleep 10
        fi
        
        # Verificar si hay errores
        if [ -f "$MT5_PATH/MQL5/Files/CRT_Evolution_Log.txt" ]; then
            last_error=$(tail -n 3 "$MT5_PATH/MQL5/Files/CRT_Evolution_Log.txt" | grep -i "error\|fail")
            if [ ! -z "$last_error" ]; then
                notify "⚠️ Error detectado: $last_error"
            fi
        fi
        
        # Mostrar estado cada hora
        if [ $(date +%M) == "00" ]; then
            notify "🟢 Trading ACTIVO - Hora NY: $current_ny - GMT: $current_gmt"
        fi
        
    else
        # FUERA DE HORARIO DE TRADING
        if pgrep -f terminal.exe > /dev/null; then
            notify "⏸️ Cerrando MT5 (Fuera de horario: $current_ny NY)"
            pkill -f terminal.exe
            sleep 5
        fi
        
        # Mostrar próximo horario de trading
        if [ $(date +%M) == "30" ]; then
            notify "⏳ Fuera de horario. Próximo trading: 3:00 AM NY (8:00 GMT)"
        fi
    fi
    
    # Esperar 1 minuto antes de revisar nuevamente
    sleep 60
done
