#!/bin/bash

echo "=== Парсинг EDID из xrandr ==="
echo

# Получаем EDID данные из xrandr для каждого монитора
for monitor in DP-2-8 DP-2-1; do
    echo "=== $monitor ==="
    
    # Извлекаем EDID из xrandr verbose вывода
    edid_data=$(xrandr --verbose | sed -n "/$monitor/,/^[A-Z]/p" | grep -A 50 "EDID:" | grep -E "^\s+[0-9a-f]" | tr -d '\t ' | tr -d '\n')
    
    if [ -n "$edid_data" ]; then
        echo "EDID данные найдены (длина: ${#edid_data} символов)"
        
        # Производитель - байты 8-9 (позиции 16-19 в hex строке)
        vendor_hex=$(echo $edid_data | cut -c17-20)
        echo "Vendor ID (hex): $vendor_hex"
        
        # Конвертируем vendor ID в читаемый формат
        if [ ${#vendor_hex} -eq 4 ]; then
            # Преобразуем hex в binary и извлекаем 3 символа производителя
            vendor_int=$((16#$vendor_hex))
            char1=$(printf "%c" $(( (vendor_int >> 10 & 0x1f) + 64 )))
            char2=$(printf "%c" $(( (vendor_int >> 5 & 0x1f) + 64 )))
            char3=$(printf "%c" $(( (vendor_int & 0x1f) + 64 )))
            echo "Vendor: $char1$char2$char3"
        fi
        
        # Product ID - байты 10-11
        product_hex=$(echo $edid_data | cut -c21-24)
        echo "Product ID (hex): $product_hex"
        
        # Serial number - байты 12-15
        serial_hex=$(echo $edid_data | cut -c25-32)
        echo "Serial (hex): $serial_hex"
        
        # Ищем дескрипторы мониторов (начинаются с 00 00 00 fc для имени модели)
        # Дескрипторы находятся в байтах 54-125
        descriptors=$(echo $edid_data | cut -c109-252)
        echo "Дескрипторы: $descriptors"
        
        # Ищем имя модели (дескриптор типа 0xfc)
        model_name=""
        for i in $(seq 0 18 72); do
            desc_start=$((109 + i))
            desc_end=$((desc_start + 35))
            if [ $desc_end -le ${#edid_data} ]; then
                desc=$(echo $edid_data | cut -c$desc_start-$desc_end)
                desc_type=$(echo $desc | cut -c9-10)
                if [ "$desc_type" = "fc" ]; then
                    # Извлекаем ASCII данные (байты 5-17 дескриптора)
                    ascii_hex=$(echo $desc | cut -c19-36)
                    model_name=$(echo $ascii_hex | xxd -r -p 2>/dev/null | tr -d '\0\n' | sed 's/[[:space:]]*$//')
                    echo "Имя модели: $model_name"
                    break
                fi
            fi
        done
        
        echo "Полный EDID:"
        echo $edid_data | fold -w 32
    else
        echo "EDID данные не найдены"
    fi
    echo
done