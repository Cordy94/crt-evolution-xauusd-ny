#!/bin/bash
echo "🔄 INSTALANDO MT5 CON WINE64..."

# Configurar Wine
export WINEARCH=win64
export WINEPREFIX=/home/trader/.wine
export WINEDEBUG=fixme-all

# Limpiar si existe
rm -rf "$WINEPREFIX"

# Inicializar Wine
echo "1. Inicializando Wine 64-bit..."
wineboot --init 2>&1 | grep -v "fixme:"
sleep 5

# Descargar instalador MT5
echo "2. Descargando MT5..."
cd /home/trader
wget -q -O mt5setup.exe https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe

# Instalar MT5 SILENCIOSAMENTE
echo "3. Instalando MT5 (esto tarda 2-3 minutos)..."
wine64 mt5setup.exe /S 2>&1 | grep -v "fixme:" | grep -v "err:" &

# Esperar instalación
INSTALL_PID=$!
for i in {1..30}; do
    if ps -p $INSTALL_PID > /dev/null; then
        echo -n "."
        sleep 5
    else
        break
    fi
done

echo ""
echo "4. Verificando instalación..."
MT5_PATH="$WINEPREFIX/drive_c/Program Files/MetaTrader 5"

if [ -f "$MT5_PATH/terminal.exe" ]; then
    echo "✅ MT5 INSTALADO CORRECTAMENTE en: $MT5_PATH"
    
    # Crear configuración básica
    mkdir -p "$MT5_PATH/MQL5/Experts"
    mkdir -p "$MT5_PATH/MQL5/Profiles/default"
    
    echo "5. Configuración creada"
    exit 0
else
    echo "❌ ERROR: MT5 no se instaló"
    echo "Contenido de $MT5_PATH:"
    ls -la "$MT5_PATH" 2>/dev/null || echo "Directorio no existe"
    exit 1
fi
