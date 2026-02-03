FROM ubuntu:22.04

# Instalar todo necesario
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    wget \
    wine64 \
    winetricks \
    xvfb \
    sudo \
    curl \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

# Configurar zona horaria
ENV TZ=America/New_York
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Crear usuario trader y cambiar permisos ANTES de copiar archivos
RUN useradd -m -s /bin/bash trader
RUN echo "trader ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Cambiar a usuario trader
USER trader
WORKDIR /home/trader
ENV WINEPREFIX=/home/trader/.wine
ENV WINEARCH=win64
ENV DISPLAY=:99

# Instalar fuentes y configurar Wine
RUN winecfg && winetricks -q corefonts

# Crear carpetas MT5
RUN mkdir -p "/home/trader/.wine/drive_c/Program Files/MetaTrader 5/MQL5/Experts"
RUN mkdir -p "/home/trader/.wine/drive_c/Program Files/MetaTrader 5/MQL5/Files"
RUN mkdir -p "/home/trader/.wine/drive_c/Program Files/MetaTrader 5/MQL5/Profiles/default"

# Copiar scripts - IMPORTANTE: Copiar como usuario trader
COPY --chown=trader:trader start.sh /home/trader/start.sh
COPY --chown=trader:trader telegram-notify.sh /home/trader/telegram-notify.sh

# Dar permisos de ejecución
RUN chmod +x /home/trader/start.sh /home/trader/telegram-notify.sh

# Exponer para posibles conexiones
EXPOSE 8080

CMD ["/home/trader/start.sh"]
