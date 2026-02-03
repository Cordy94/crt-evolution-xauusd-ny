# 🦅 CRT Evolution Sniper V7.2 - XAUUSD M15

EA de trading automático para MetaTrader 5 especializado en XAUUSD.

## 📊 Configuración

### Horario de Trading
- **Apertura:** 3:00 AM NY Time (GMT-5)
- **Cierre:** 5:00 PM NY Time (GMT-5)  
- **Equivalente GMT:** 8:00 AM - 22:00 PM GMT
- **Símbolo:** XAUUSD
- **Timeframe:** M15

### Estrategia
- Solo operaciones de COMPRA
- Martingale basado en balance
- Stop Loss dinámico
- Take Profit 5:1

## 🚀 Despliegue en Railway

### 1. Variables de Entorno en Railway:

```env
MT5_LOGIN=91033361
MT5_PASSWORD=tu_password
MT5_SERVER=LiteFinance-MT5-Demo

EA_INITIAL_LOT=0.01
EA_STEP_DOLLARS=10.0
EA_MAX_LOT=10.0
EA_SL_POINTS=110
EA_TP_MULTIPLIER=5
EA_NY_START=8
EA_NY_END=22
EA_MAGIC=240226

TELEGRAM_BOT_TOKEN=opcional
TELEGRAM_CHAT_ID=opcional
