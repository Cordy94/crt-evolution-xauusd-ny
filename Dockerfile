FROM ubuntu:22.04

# Instalar wine64 SOLAMENTE
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    wget \
    wine64 \
    xvfb \
    sudo \
    curl \
    tzdata \
    p7zip-full \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# Configurar NY time
ENV TZ=America/New_York
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Crear usuario
RUN useradd -m -u 1000 -s /bin/bash trader && \
    echo "trader ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER trader
WORKDIR /home/trader

# Configurar Wine 64-bit
ENV WINEARCH=win64
ENV WINEPREFIX=/home/trader/.wine
ENV WINEDLLOVERRIDES="mscoree,mshtml="
ENV DISPLAY=:99

# Inicializar Wine limpio
RUN wineboot --init 2>/dev/null && sleep 3

USER root

# Copiar scripts - con verificación de existencia
COPY install-mt5.sh /home/trader/install-mt5.sh
COPY start.sh /home/trader/start.sh

# Solo copiar monitor.sh si existe
COPY monitor.sh /home/trader/monitor.sh || echo "monitor.sh no encontrado, continuando..."

RUN chown trader:trader /home/trader/*.sh 2>/dev/null || true && \
    chmod +x /home/trader/*.sh 2>/dev/null || true

USER trader

EXPOSE 8080

CMD ["/home/trader/start.sh"]
