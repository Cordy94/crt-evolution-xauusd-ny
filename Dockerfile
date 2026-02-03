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
    ssh \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

# Configurar zona horaria NY
ENV TZ=America/New_York
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Crear usuario
RUN useradd -m -s /bin/bash trader
RUN echo "trader ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
RUN echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
RUN echo "PermitRootLogin no" >> /etc/ssh/sshd_config
RUN echo "AllowUsers trader" >> /etc/ssh/sshd_config

# Configurar Wine
USER trader
WORKDIR /home/trader
ENV WINEPREFIX=/home/trader/.wine
ENV WINEARCH=win64
ENV DISPLAY=:99

# Instalar fuentes
RUN winecfg && winetricks -q corefonts

# Configurar SSH para trader
RUN mkdir -p /home/trader/.ssh
RUN ssh-keygen -t rsa -f /home/trader/.ssh/id_rsa -N ""
RUN cat /home/trader/.ssh/id_rsa.pub >> /home/trader/.ssh/authorized_keys
RUN chmod 700 /home/trader/.ssh && chmod 600 /home/trader/.ssh/*

# Scripts
COPY start.sh /home/trader/start.sh
COPY telegram-notify.sh /home/trader/telegram-notify.sh
RUN chmod +x /home/trader/start.sh /home/trader/telegram-notify.sh

# Puerto SSH
EXPOSE 22

CMD ["/home/trader/start.sh"]
