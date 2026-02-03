#!/bin/bash

# === CONFIGURACIÓN SSH PARA ACCESO DESDE CUBA ===
# Iniciar SSH daemon en segundo plano
sudo /usr/sbin/sshd -D &
echo "SSH iniciado en puerto 22"
echo "Clave privada para conexión:"
cat /home/trader/.ssh/id_rsa
echo "=========================================="

# Continuar con el resto del script...
