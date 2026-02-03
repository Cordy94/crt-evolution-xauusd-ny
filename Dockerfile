FROM ubuntu:22.04

# Instalar TODO necesario para Wine headless
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    wget \
    wine64 \
    winetricks \
    xvfb \
    sudo \
    curl \
    tzdata \
    tmux \
    nano \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# Configurar zona horaria NY
ENV TZ=America/New_York
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Crear usuario trader
RUN useradd -m -s /bin/bash trader
RUN echo "trader ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER trader
WORKDIR /home/trader

# Configurar Wine para modo sin pantalla
ENV WINEPREFIX=/home/trader/.wine
ENV WINEARCH=win64
ENV DISPLAY=:99
ENV WINEDLLOVERRIDES="mscoree,mshtml="
ENV WINEDEBUG=-all

# Crear configuración básica de Wine SIN interfaz
RUN mkdir -p /home/trader/.wine
RUN echo -e '[wine]\n"Desktop" = "800x600"\n"GL" = "disabled"' > /home/trader/.wine/user.reg
RUN echo -e '[Software\\Wine\\X11 Driver]\n"GrabFullScreen" = "N"' > /home/trader/.wine/system.reg
RUN echo -e '[Software\\Wine\\Drivers]\n"Audio" = ""\n"Graphics" = "x11"' >> /home/trader/.wine/system.reg

# Instalar fuentes básicas sin interfaz
RUN winetricks -q corefonts --unattended 2>/dev/null || echo "Fonts installed"

# Crear estructura MT5
RUN mkdir -p "/home/trader/.wine/drive_c/Program Files/MetaTrader 5/MQL5/Experts"
RUN mkdir -p "/home/trader/.wine/drive_c/Program Files/MetaTrader 5/MQL5/Files"
RUN mkdir -p "/home/trader/.wine/drive_c/Program Files/MetaTrader 5/logs"

# Copiar scripts
COPY start.sh /home/trader/start.sh
COPY monitor-ea.sh /home/trader/monitor-ea.sh
RUN chmod +x /home/trader/*.sh

EXPOSE 8080

CMD ["/home/trader/start.sh"]
