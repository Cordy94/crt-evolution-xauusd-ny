#!/bin/bash

echo "=== CRT EVOLUTION - XAUUSD M15 ==="
echo "Inicio: $(date)"
echo "Hora NY: $(TZ=America/New_York date)"

# Variables
export MT5_LOGIN="${MT5_LOGIN}"
export MT5_PASSWORD="${MT5_PASSWORD}"
export MT5_SERVER="${MT5_SERVER}"
export EA_NAME="CRT_Evolution_SNIPER_V7_2.ex5"
export SYMBOL="XAUUSD"

# Configurar X virtual framebuffer
export DISPLAY=:99
Xvfb :99 -screen 0 1024x768x16 &
sleep 3

# Ruta MT5
MT5_PATH="/home/trader/.wine64/drive_c/Program Files/MetaTrader 5"
mkdir -p "$MT5_PATH/MQL5/Experts"
mkdir -p "$MT5_PATH/MQL5/Profiles/default"

# Copiar EA
if [ -f "/home/trader/$EA_NAME" ]; then
    cp "/home/trader/$EA_NAME" "$MT5_PATH/MQL5/Experts/"
    echo "✅ EA copiado"
fi

# Crear config.ini
cat > "$MT5_PATH/config.ini" << EOF
[Common]
Login=${MT5_LOGIN}
Password=${MT5_PASSWORD}
Server=${MT5_SERVER}
Expert=${EA_NAME}
ExpertParameters=ea.set
Symbol=${SYMBOL}
Period=15
Model=0
EnableReports=0
EnableDDE=0
EnableNews=0

[Charts]
Enable=0
EOF

# Crear ea.set
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
Comment=CRT_Evolution
EOF

echo "📁 Configuración creada"

# Instalar MT5 si no existe
if [ ! -f "$MT5_PATH/terminal.exe" ]; then
    echo "📦 Descargando MT5..."
    cd "$MT5_PATH"
    wget -q -O mt5setup.exe https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe
    
    echo "⚙️ Instalando MT5 (esto puede tardar)..."
    wine64 mt5setup.exe /S 2>&1 | grep -v "fixme:" | grep -v "err:" &
    sleep 30
    
    if [ -f "terminal.exe" ]; then
        echo "✅ MT5 instalado"
    else
        echo "⚠️ Reintentando instalación..."
        wine64 mt5setup.exe /S &
        sleep 20
    fi
else
    echo "✅ MT5 ya instalado"
fi

# Iniciar servidor web de monitoreo
echo "🌐 Servidor monitoreo puerto 8080..."
/home/trader/monitor-ea.sh &

# Iniciar MT5
echo "🚀 Iniciando MT5..."
cd "$MT5_PATH"
wine64 terminal.exe /config:config.ini 2>&1 | grep -v "fixme:" &

echo "✅ Sistema iniciado"
echo "Monitorear: curl http://localhost:8080/status"

# Mantener contenedor vivo
while true; do
    if ! pgrep -f terminal.exe > /dev/null; then
        echo "🔄 Reiniciando MT5..."
        cd "$MT5_PATH"
        wine64 terminal.exe /config:config.ini 2>&1 | grep -v "fixme:" &
    fi
    sleep 60
done
