#!/bin/bash

echo "╔══════════════════════════════════════════╗"
echo "║     CRT EVOLUTION - XAUUSD M15           ║"
echo "║     Render.com + Wine64                  ║"
echo "╚══════════════════════════════════════════╝"

# Configurar display virtual
export DISPLAY=:99
Xvfb :99 -screen 0 1024x768x16 &
sleep 2

# Variables de entorno
export MT5_LOGIN="${MT5_LOGIN:-91033361}"
export MT5_PASSWORD="${MT5_PASSWORD}"
export MT5_SERVER="${MT5_SERVER:-LiteFinance-MT5-Demo}"
export EA_NAME="CRT_Evolution_SNIPER_V7_2.ex5"
export SYMBOL="XAUUSD"

# Configurar Wine
export WINEARCH=win64
export WINEPREFIX=/home/trader/.wine
export WINEDEBUG=-all

# Ruta MT5
MT5_PATH="$WINEPREFIX/drive_c/Program Files/MetaTrader 5"

# PASO 1: Instalar MT5 si no existe
if [ ! -f "$MT5_PATH/terminal.exe" ]; then
    echo "📦 MT5 no encontrado. Instalando..."
    /home/trader/install-mt5.sh
    
    if [ ! -f "$MT5_PATH/terminal.exe" ]; then
        echo "❌ ERROR CRÍTICO: No se pudo instalar MT5"
        echo "Intentando instalación alternativa..."
        
        # Método alternativo: Extraer directamente
        cd /home/trader
        wget -q -O mt5.zip https://www.mql5.com/es/download?server=LiteFinance-MT5-Demo
        if [ -f "mt5.zip" ]; then
            7z x mt5.zip -o"$MT5_PATH"
        fi
    fi
else
    echo "✅ MT5 ya instalado"
fi

# PASO 2: Copiar EA
if [ -f "/home/trader/$EA_NAME" ]; then
    mkdir -p "$MT5_PATH/MQL5/Experts"
    cp "/home/trader/$EA_NAME" "$MT5_PATH/MQL5/Experts/"
    echo "✅ EA copiado a MQL5/Experts/"
else
    echo "⚠️ Archivo EA no encontrado: $EA_NAME"
    ls -la /home/trader/
fi

# PASO 3: Crear configuración
echo "⚙️ Creando configuración MT5..."

# config.ini
cat > "$MT5_PATH/config.ini" << EOF
[Common]
Login=$MT5_LOGIN
Password=$MT5_PASSWORD
Server=$MT5_SERVER
Expert=$EA_NAME
ExpertParameters=ea.set
Symbol=$SYMBOL
Period=15
Model=0
EnableReports=0
EnableDDE=0
EnableNews=0
EnableMail=0

[Terminal]
ShowLog=0
ShowJournal=0
ShowExperts=1

[Charts]
Enable=0
EOF

# ea.set
mkdir -p "$MT5_PATH/MQL5/Profiles/default"
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

echo "✅ Configuración creada"

# PASO 4: Iniciar servidor web de monitoreo
echo "🌐 Iniciando servidor web en puerto 8080..."
/home/trader/monitor.sh &

# PASO 5: Iniciar MT5
echo "🚀 Iniciando MT5 con EA..."
cd "$MT5_PATH"

# Primero, configurar registro para modo headless
cat > /home/trader/headless.reg << 'EOF'
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Software\Wine\X11 Driver]
"Decorated"="N"
"GrabFullScreen"="N"
"Managed"="N"
"UseTakeFocus"="N"

[HKEY_CURRENT_USER\Software\Wine\Explorer]
"Desktop"="800x600"
EOF

wine64 regedit /S /home/trader/headless.reg 2>/dev/null

# Ejecutar MT5 en background
wine64 terminal.exe /config:config.ini 2>&1 | grep -v "fixme:" &
MT5_PID=$!

sleep 10

if ps -p $MT5_PID > /dev/null; then
    echo "✅ MT5 iniciado (PID: $MT5_PID)"
else
    echo "⚠️ MT5 no se mantuvo ejecutando, intentando sin parámetros..."
    wine64 terminal.exe 2>&1 | grep -v "fixme:" &
fi

# PASO 6: Monitoreo continuo
echo ""
echo "========================================"
echo "🦅 CRT Evolution operativo"
echo "📊 Monitoreo: http://localhost:8080"
echo "⏰ Hora NY: $(TZ=America/New_York date '+%H:%M')"
echo "========================================"

# Bucle principal
while true; do
    # Verificar MT5
    if ! pgrep -f terminal.exe > /dev/null 2>&1; then
        echo "🔄 Reiniciando MT5..."
        cd "$MT5_PATH"
        wine64 terminal.exe /config:config.ini 2>&1 | grep -v "fixme:" &
        sleep 10
    fi
    
    # Mantener contenedor activo
    sleep 60
done
