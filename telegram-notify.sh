#!/bin/bash
# Notificaciones para CRT Evolution Sniper

TOKEN="${TELEGRAM_BOT_TOKEN}"
CHAT_ID="${TELEGRAM_CHAT_ID}"
MESSAGE="$1"

if [ -z "$TOKEN" ] || [ -z "$CHAT_ID" ]; then
    echo "❌ Telegram no configurado. Configure TELEGRAM_BOT_TOKEN y TELEGRAM_CHAT_ID"
    exit 0
fi

# Obtener hora NY
HORA_NY=$(TZ=America/New_York date '+%Y-%m-%d %H:%M:%S')

# Enviar mensaje
RESPONSE=$(curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
    -d "chat_id=${CHAT_ID}" \
    -d "text=🦅 <b>CRT Evolution Sniper</b>
⏰ <i>$HORA_NY NY</i>
📊 $MESSAGE" \
    -d "parse_mode=HTML" \
    -d "disable_notification=false")

# Verificar si fue exitoso
if echo "$RESPONSE" | grep -q '"ok":true'; then
    echo "✅ Notificación enviada: $MESSAGE"
else
    echo "❌ Error enviando notificación: $RESPONSE"
fi
