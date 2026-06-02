#!/bin/bash

echo "=== Информация о мониторах ==="
echo

# Проверяем активные мониторы
echo "Активные мониторы:"
xrandr --listmonitors
echo

# Получаем EDID информацию для каждого активного порта
for edid_file in /sys/class/drm/card1-*/edid; do
    port=$(basename $(dirname $edid_file))
    
    if [ -s "$edid_file" ]; then
        echo "=== $port ==="
        echo "EDID размер: $(wc -c < $edid_file) bytes"
        
        # Извлекаем hex данные EDID
        edid_hex=$(xxd -p -c 256 "$edid_file")
        
        # Производитель (байты 8-9, биты упакованы)
        vendor_bytes=$(echo $edid_hex | cut -c17-20)
        echo "Vendor ID (hex): $vendor_bytes"
        
        # Модель монитора (дескриптор начинается с байта 54)
        model_desc=$(echo $edid_hex | cut -c109-140)
        echo "Model descriptor (hex): $model_desc"
        
        # Серийный номер (если есть)
        serial_desc=$(echo $edid_hex | cut -c141-172)
        echo "Serial descriptor (hex): $serial_desc"
        
        echo "Полный EDID:"
        echo $edid_hex | fold -w 32
        echo
    fi
done

# Также проверим через hwinfo если доступно
if command -v hwinfo >/dev/null 2>&1; then
    echo "=== hwinfo информация ==="
    hwinfo --monitor --short
fi

# И через lshw если доступно
if command -v lshw >/dev/null 2>&1; then
    echo "=== lshw информация ==="
    lshw -c display 2>/dev/null | grep -E "(product|vendor|serial|description)"
fi