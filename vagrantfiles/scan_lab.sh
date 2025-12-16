#!/bin/bash

#scan_lab.sh - автомматическое сканирование лабораторной сети

echo "=== Сканирование лаборатории 192.168.56.0/24 ==="

#Создаём заголовок для файла инвентаря Ansible
echo "[all]" > inventory.ini

#Перебираем адреса для нашей подсети
for ip in {10..12}; do 
    target="192.168.56.$ip"
    echo -n "Проверяем $target... "

    #пингуем хост (1 пакет, таймаут 1 секунда)
    if ping -c 1 -W 1 "$target" &> /dev/null; then
        echo "Доступен"
        echo "$target" >> inventory.ini
    else
        echo "Недоступен"
    fi
done 

echo ""
echo "=== Результат сохранён в inventory.ini ==="
cat inventory.ini
