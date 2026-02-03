FROM ubuntu:22.04

# Habilitar arquitectura i386 para wine32
RUN dpkg --add-architecture i386

# Instalar wine64 Y wine32
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    wget \
    wine64 \
    wine32 \
    winetricks \
    xvfb \
    sudo \
    curl \
    tzdata \
    cabextract \
    fonts-wine \
    && rm -rf /var/lib/apt/lists/*

# Configurar zona horaria NY
ENV TZ=America/New_York
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Crear usuario trader con UID 1000
RUN useradd -m -u 1000 -s /bin/bash trader && \
    echo "trader ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER trader
WORKDIR /home/trader

# Configurar Wine (64-bit only, sin wine32 conflictos)
ENV WINEPREFIX=/home/trader/.wine64
ENV WINEARCH=win64
ENV DISPLAY=:99
ENV WINEDLLOVERRIDES="mscoree,mshtml="
ENV WINEDEBUG=-all

# Inicializar Wine sin interfaz
RUN wineboot --init 2>/dev/null && sleep 3

# Configurar registro para modo headless
RUN mkdir -p /home/trader/.wine64
RUN echo -e '[Software\\Wine\\X11 Driver]\n"GrabFullScreen"="N"' > /home/trader/.wine64/system.reg
RUN echo -e '[Software\\Wine\\Drivers]\n"Graphics"="x11"' >> /home/trader/.wine64/system.reg

# Crear estructura MT5
RUN mkdir -p "/home/trader/.wine64/drive_c/Program Files/MetaTrader 5/MQL5/Experts"
RUN mkdir -p "/home/trader/.wine64/drive_c/Program Files/MetaTrader 5/MQL5/Files"

# Copiar scripts ANTES de cambiar usuario (como root)
USER root
COPY start.sh /home/trader/start.sh
COPY monitor-ea.sh /home/trader/monitor-ea.sh
RUN chown trader:trader /home/trader/start.sh /home/trader/monitor-ea.sh && \
    chmod +x /home/trader/start.sh /home/trader/monitor-ea.sh

# Volver a usuario trader
USER trader

EXPOSE 8080

CMD ["/home/trader/start.sh"]
