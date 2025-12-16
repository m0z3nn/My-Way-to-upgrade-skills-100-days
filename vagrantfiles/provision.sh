#!/bin/bash

# Скрипт начальной настройки для Ubuntu 24.04
# Выполняется от root при создании ВМ

# Выходим при любой ошибке
set -e

# КРИТИЧЕСКИ ВАЖНО: Заставляем apt работать в неинтерактивном режиме
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

# Логируем начало выполнения
echo "=== Начало provisioning для $(hostname) ==="

# 1. Обновляем списки пакетов (без вывода лишней информации)
echo "[1/6] Обновление списков пакетов..."
apt-get update -q -y 2>/dev/null | grep -v "Reading package lists"

# 2. Обновляем установленные пакеты (БЕЗ перезагрузки и с автоматическим принятием)
echo "[2/6] Обновление установленных пакетов..."
apt-get upgrade -q -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" 2>/dev/null | tail -5

# 3. Устанавливаем базовые пакеты (включая openssh-server)
echo "[3/6] Установка базовых пакетов..."
apt-get install -y -q \
    curl \
    wget \
    git \
    vim \
    htop \
    net-tools \
    traceroute \
    python3 \
    python3-pip \
    tree \
    jq \
    unzip \
    software-properties-common \
    openssh-server 2>/dev/null | tail -5

# 4. Немедленно настраиваем и запускаем SSH (до возможных перезагрузок)
echo "[4/6] Настройка SSH сервера..."
systemctl enable ssh
systemctl start ssh

# 5. Разрешаем парольную аутентификацию для SSH (для упрощения лаборатории)
sed -i 's/#\?PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart ssh

# 6. Создаем пользователя ansible (если ещё не создан)
echo "[5/6] Создание пользователя ansible..."
if ! id "ansible" &>/dev/null; then
    useradd -m -s /bin/bash ansible
    echo "ansible:ansible" | chpasswd
    echo "ansible ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/ansible
    chmod 0440 /etc/sudoers.d/ansible
fi

# 7. Настраиваем ключи Vagrant
echo "[6/6] Настройка ключей Vagrant..."
mkdir -p /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh
wget -q https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant.pub -O /home/vagrant/.ssh/authorized_keys
chmod 600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant:vagrant /home/vagrant/.ssh

echo "=== Provisioning успешно завершен! ==="
echo "Система: $(lsb_release -d | cut -f2)"
echo "IP адрес: $(hostname -I | awk '{print $2}')"
