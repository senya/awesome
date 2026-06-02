#!/bin/bash

echo "=== Стабильные идентификаторы мониторов ==="
echo

# Функция для конвертации hex в ASCII
hex_to_ascii() {
    echo "$1" | xxd -r -p 2>/dev/null | tr -d '\0\n' | sed 's/[[:space:]]*$//'
}

# Функция для декодирования vendor ID
decode_vendor() {
    local vendor_hex="$1"
    local vendor_int=$((16#$vendor_hex))
    local char1=$(printf "%c" $(( (vendor_int >> 10 & 0x1f) + 64 )))
    local char2=$(printf "%c" $(( (vendor_int >> 5 & 0x1f) + 64 )))
    local char3=$(printf "%c" $(( (vendor_int & 0x1f) + 64 )))
    echo "$char1$char2$char3"
}

# Обрабатываем каждый монитор
for monitor in DP-2-8 DP-2-1; do
    echo "=== $monitor ==="
    
    # Извлекаем EDID
    edid_data=$(xrandr --verbose | sed -n "/$monitor/,/^[A-Z]/p" | grep -A 50 "EDID:" | grep -E "^\s+[0-9a-f]" | tr -d '\t ' | tr -d '\n')
    
    if [ -n "$edid_data" ]; then
        # Основные идентификаторы
        vendor_hex=$(echo $edid_data | cut -c17-20)
        product_hex=$(echo $edid_data | cut -c21-24)
        serial_hex=$(echo $edid_data | cut -c25-32)
        
        vendor_name=$(decode_vendor $vendor_hex)
        
        echo "Производитель: $vendor_name (0x$vendor_hex)"
        echo "Product ID: 0x$product_hex"
        echo "Серийный номер (hex): $serial_hex"
        
        # Декодируем серийный номер в десятичный
        serial_dec=$((16#$serial_hex))
        echo "Серийный номер (dec): $serial_dec"
        
        # Ищем имя модели в дескрипторах
        model_found=false
        serial_found=false
        
        # Проверяем 4 дескриптора (каждый по 18 байт, начиная с байта 54)
        for desc_num in 0 1 2 3; do
            desc_start=$((109 + desc_num * 36))  # 54*2 + desc_num*18*2
            desc_end=$((desc_start + 35))
            
            if [ $desc_end -le ${#edid_data} ]; then
                desc=$(echo $edid_data | cut -c$desc_start-$desc_end)
                desc_type=$(echo $desc | cut -c9-10)
                
                case $desc_type in
                    "fc")  # Monitor name
                        if [ "$model_found" = false ]; then
                            ascii_hex=$(echo $desc | cut -c19-36)
                            model_name=$(hex_to_ascii $ascii_hex)
                            echo "Модель: $model_name"
                            model_found=true
                        fi
                        ;;
                    "ff")  # Monitor serial number string
                        if [ "$serial_found" = false ]; then
                            ascii_hex=$(echo $desc | cut -c19-36)
                            serial_string=$(hex_to_ascii $ascii_hex)
                            echo "Серийный номер (строка): $serial_string"
                            serial_found=true
                        fi
                        ;;
                esac
            fi
        done
        
        # Создаем уникальный идентификатор
        unique_id="${vendor_name}_${product_hex}_${serial_hex}"
        echo "Уникальный ID: $unique_id"
        
        # Также показываем connector ID из xrandr
        connector_id=$(xrandr --verbose | sed -n "/$monitor/,/^[A-Z]/p" | grep "CONNECTOR_ID:" | awk '{print $2}')
        echo "Connector ID: $connector_id"
        
    else
        echo "EDID данные не найдены"
    fi
    echo
done

echo "=== Рекомендации ==="
echo "Для стабильной идентификации мониторов используйте:"
echo "1. Уникальный ID (Vendor_ProductID_Serial) - самый надежный"
echo "2. Connector ID - может меняться при переподключении"
echo "3. Комбинацию модели и серийного номера"
echo "4. EDID checksum для полной уверенности"