#!/bin/bash

echo "╔══════════════════════════════════════════╗"
echo "║     CRT EVOLUTION SNIPER V7.2            ║"
echo "║     XAUUSD M15 - Render.com              ║"
echo "║     Horario: 3AM-5PM NY Time             ║"
echo "╚══════════════════════════════════════════╝"

# ============================================
# CONFIGURACIÓN INICIAL
# ============================================

# Crear monitor.sh si no existe
if [ ! -f "/home/trader/monitor.sh" ]; then
    echo "📝 Creando monitor.sh automático..."
    cat > /home/trader/monitor.sh << 'EOF'
#!/bin/bash
while true; do
    {
        echo -e "HTTP/1.1 200 OK\r\n"
        echo -e "Content-Type: text/plain\r\n\r\n"
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
        echo "Endpoints: /status (this)"
    } | nc -l -p 8080 -q 1 2>/dev/null
    sleep 1
done
EOF
    chmod +x /home/trader/monitor.sh
    echo "✅ monitor.sh creado"
fi

# Configurar X virtual framebuffer
echo "🖥️ Configurando Xvfb..."
export DISPLAY=:99
Xvfb :99 -screen 0 1024x768x16 &
sleep 3

# ============================================
# VARIABLES DE ENTORNO
# ============================================

export MT5_LOGIN="${MT5_LOGIN:-91033361}"
export MT5_PASSWORD="${MT5_PASSWORD}"
export MT5_SERVER="${MT5_SERVER:-LiteFinance-MT5-Demo}"
export EA_NAME="CRT_Evolution_SNIPER_V7_2.ex5"
export SYMBOL="XAUUSD"
export TIMEFRAME="15"

# Configurar Wine
export WINEARCH=win64
export WINEPREFIX=/home/trader/.wine
export WINEDEBUG=-all
export WINEDLLOVERRIDES="mscoree,mshtml="

# Ruta MT5
MT5_PATH="$WINEPREFIX/drive_c/Program Files/MetaTrader 5"

# ============================================
# INSTALACIÓN DE MT5
# ============================================

echo "🔍 Verificando instalación MT5..."

if [ ! -f "$MT5_PATH/terminal.exe" ]; then
    echo "📦 MT5 no encontrado. Instalando..."
    
    # Limpiar prefix si existe
    rm -rf "$WINEPREFIX"
    
    # Inicializar Wine
    wineboot --init 2>/dev/null
    sleep 5
    
    # Descargar instalador MT5
    cd /home/trader
    wget -q -O mt5setup.exe https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe
    
    echo "⚙️ Instalando MT5 (puede tardar 2-3 minutos)..."
    
    # Instalar silenciosamente
    wine64 mt5setup.exe /S 2>&1 | grep -v "fixme:" | grep -v "err:" &
    INSTALL_PID=$!
    
    # Esperar instalación
    for i in {1..30}; do
        if ps -p $INSTALL_PID > /dev/null; then
            echo -n "."
            sleep 5
        else
            break
        fi
    done
    echo ""
    
    # Verificar instalación
    if [ -f "$MT5_PATH/terminal.exe" ]; then
        echo "✅ MT5 instalado correctamente"
    else
        echo "⚠️ MT5 puede no haberse instalado completamente"
        echo "Contenido de $MT5_PATH:"
        ls -la "$MT5_PATH" 2>/dev/null || echo "Directorio no existe"
    fi
else
    echo "✅ MT5 ya instalado"
fi

# ============================================
# CONFIGURACIÓN DEL EA
# ============================================

echo "⚙️ Configurando EA..."

# Crear directorios necesarios
mkdir -p "$MT5_PATH/MQL5/Experts"
mkdir -p "$MT5_PATH/MQL5/Profiles/default"
mkdir -p "$MT5_PATH/MQL5/Files"

# Copiar EA
if [ -f "/home/trader/$EA_NAME" ]; then
    cp "/home/trader/$EA_NAME" "$MT5_PATH/MQL5/Experts/"
    echo "✅ EA copiado a MQL5/Experts/"
else
    echo "⚠️ Archivo EA no encontrado: $EA_NAME"
    echo "Archivos en /home/trader/:"
    ls -la /home/trader/
fi

# Crear config.ini
cat > "$MT5_PATH/config.ini" << EOF
[Common]
Login=$MT5_LOGIN
Password=$MT5_PASSWORD
Server=$MT5_SERVER
Expert=$EA_NAME
ExpertParameters=ea.set
Symbol=$SYMBOL
Period=$TIMEFRAME
Model=0
EnableReports=0
EnableDDE=0
EnableNews=0
EnableMail=0
EnableSound=0

[Terminal]
ShowLog=0
ShowJournal=0
ShowExperts=1
AutoTrading=1
ConfirmCloseOrder=0
ConfirmDeleteOrder=0
ConfirmOrderExecution=0

[Charts]
Enable=0
Height=0
Width=0
QuickLaunch=0

[Tester]
Expert=$EA_NAME
ExpertParameters=ea.set
Symbol=$SYMBOL
Period=$TIMEFRAME
Model=0
Optimization=0
ForwardMode=0
ForwardDate=2024.01.01
Deposit=10000
Currency=USD
ProfitInPips=1
EOF

# Crear ea.set con parámetros
cat > "$MT5_PATH/MQL5/Profiles/default/ea.set" << EOF
[Parameters]
InitialLot=${EA_INITIAL_LOT:-0.01}
StepDollars=${EA_STEP_DOLLARS:-10.0}
MaxLotLimit=${EA_MAX_LOT:-10.0}
SL_Points=${EA_SL_POINTS:-110}
TP_Multiplier=${EA_TP_MULTIPLIER:-5}
NY_Start_Hour=${EA_NY_START:-8}      # 8:00 GMT = 3:00 AM NY
NY_End_Hour=${EA_NY_END:-22}         # 22:00 GMT = 5:00 PM NY
MagicNumber=${EA_MAGIC:-240226}
Comment=CRT_Evolution_Render_XAUUSD
EOF

# Crear script de inicialización MQL5
cat > "$MT5_PATH/MQL5/Scripts/init_crt.mq5" << 'EOF_MQL'
//+------------------------------------------------------------------+
//|                         init_crt.mq5                             |
//+------------------------------------------------------------------+
void OnStart()
{
    Print("========================================");
    Print("CRT Evolution Sniper V7.2 - Inicializado");
    Print("Account: ", AccountInfoInteger(ACCOUNT_LOGIN));
    Print("Server: ", AccountInfoString(ACCOUNT_SERVER));
    Print("Symbol: ", _Symbol);
    Print("Balance: $", AccountInfoDouble(ACCOUNT_BALANCE));
    Print("========================================");
    
    // Forzar recarga del EA
    EventSetTimer(1);
}
EOF_MQL

echo "✅ Configuración completada"

# ============================================
# INICIAR SERVICIOS
# ============================================

# Iniciar servidor web de monitoreo
echo "🌐 Iniciando servidor web en puerto 8080..."
/home/trader/monitor.sh &
sleep 2

# Configurar registro para modo headless
echo "🛠️ Configurando Wine para modo sin interfaz..."
cat > /home/trader/headless.reg << 'EOF'
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Software\Wine\X11 Driver]
"Decorated"="N"
"GrabFullScreen"="N"
"Managed"="N"
"UseTakeFocus"="N"
"Desktop"="800x600"

[HKEY_CURRENT_USER\Software\Wine\Explorer]
"Desktop"="800x600"

[HKEY_CURRENT_USER\Control Panel\Colors]
"ActiveBorder"="200 200 200"
"ActiveTitle"="10 36 106"
"AppWorkSpace"="128 128 128"
"Background"="0 0 0"
"ButtonAlternateFace"="181 181 181"
"ButtonDkShadow"="64 64 64"
"ButtonFace"="240 240 240"
"ButtonHilight"="255 255 255"
"ButtonLight"="227 227 227"
"ButtonShadow"="128 128 128"
"ButtonText"="0 0 0"
"GradientActiveTitle"="166 202 240"
"GradientInactiveTitle"="192 192 192"
"GrayText"="128 128 128"
"Hilight"="10 36 106"
"HilightText"="255 255 255"
"InactiveBorder"="244 247 252"
"InactiveTitle"="128 128 128"
"InactiveTitleText"="0 0 0"
"InfoText"="0 0 0"
"InfoWindow"="255 255 225"
"Menu"="240 240 240"
"MenuBar"="240 240 240"
"MenuHilight"="10 36 106"
"MenuText"="0 0 0"
"Scrollbar"="200 200 200"
"TitleText"="255 255 255"
"Window"="255 255 255"
"WindowFrame"="0 0 0"
"WindowText"="0 0 0"
EOF

wine64 regedit /S /home/trader/headless.reg 2>/dev/null

# Iniciar MT5
echo "🚀 Iniciando MT5 con EA..."
cd "$MT5_PATH"

# Ejecutar MT5 en background
wine64 terminal.exe /config:config.ini /skipupdate 2>&1 | grep -v "fixme:" &
MT5_PID=$!

sleep 15

# Verificar que MT5 esté corriendo
if ps -p $MT5_PID > /dev/null; then
    echo "✅ MT5 iniciado correctamente (PID: $MT5_PID)"
    
    # Crear archivo de log
    echo "$(date) - MT5 iniciado con PID $MT5_PID" > /home/trader/mt5-status.log
else
    echo "⚠️ MT5 no se inició, intentando método alternativo..."
    
    # Intentar sin parámetros
    wine64 terminal.exe 2>&1 | grep -v "fixme:" &
    sleep 10
    
    if pgrep -f terminal.exe > /dev/null; then
        echo "✅ MT5 iniciado (método alternativo)"
    else
        echo "❌ No se pudo iniciar MT5"
    fi
fi

# ============================================
# MONITOREO CONTINUO
# ============================================

echo ""
echo "========================================"
echo "🦅 CRT Evolution operativo"
echo "📊 Monitoreo: http://localhost:8080/status"
echo "⏰ Hora NY: $(TZ=America/New_York date '+%H:%M')"
echo "💰 Cuenta: $MT5_LOGIN"
echo "📈 Par: $SYMBOL M15"
echo "========================================"
echo ""
echo "📱 Para monitorear desde Termux:"
echo "curl https://$(hostname).onrender.com/status"
echo ""

# Función para verificar horario de trading
is_trading_time() {
    local hora_gmt=$(date -u +"%H")
    if [ $hora_gmt -ge 8 ] && [ $hora_gmt -lt 22 ]; then
        return 0  # true - es hora de trading
    else
        return 1  # false - no es hora
    fi
}

# Bucle principal de monitoreo
MINUTO_ANTERIOR="-1"

while true; do
    # Obtener hora actual
    HORA_NY=$(TZ=America/New_York date '+%H:%M')
    HORA_GMT=$(date -u '+%H:%M')
    MINUTO_ACTUAL=$(date +%M)
    
    # Verificar MT5 cada minuto
    if [ "$MINUTO_ACTUAL" != "$MINUTO_ANTERIOR" ]; then
        MINUTO_ANTERIOR="$MINUTO_ACTUAL"
        
        if ! pgrep -f terminal.exe > /dev/null; then
            echo "🔄 [$(date '+%H:%M')] Reiniciando MT5..."
            cd "$MT5_PATH"
            pkill -f terminal.exe 2>/dev/null
            sleep 2
            wine64 terminal.exe /config:config.ini 2>&1 | grep -v "fixme:" &
            sleep 10
        fi
    fi
    
    # Mostrar estado cada 15 minutos
    if [ "$MINUTO_ACTUAL" = "00" ] || [ "$MINUTO_ACTUAL" = "15" ] || [ "$MINUTO_ACTUAL" = "30" ] || [ "$MINUTO_ACTUAL" = "45" ]; then
        if is_trading_time; then
            echo "🟢 [$HORA_NY NY] Trading ACTIVO - MT5: $(pgrep -f terminal.exe 2>/dev/null || echo 'STOPPED')"
        else
            echo "⏸️ [$HORA_NY NY] Fuera de horario"
        fi
    fi
    
    # Mantener contenedor activo
    sleep 30
done
