#!/bin/bash

echo "=== Полная информация о мониторах ==="
echo

# Функция для правильного декодирования vendor ID
decode_vendor_correct() {
    local vendor_hex="$1"
    # Конвертируем в little-endian порядок для правильного декодирования
    local byte1="0x${vendor_hex:2:2}"
    local byte2="0x${vendor_hex:0:2}"
    local vendor_int=$(( (byte1 << 8) | byte2 ))
    
    local char1=$(printf "%c" $(( ((vendor_int >> 10) & 0x1f) + 64 )))
    local char2=$(printf "%c" $(( ((vendor_int >> 5) & 0x1f) + 64 )))
    local char3=$(printf "%c" $(( (vendor_int & 0x1f) + 64 )))
    echo "$char1$char2$char3"
}

# Функция для конвертации hex в ASCII
hex_to_ascii() {
    echo "$1" | xxd -r -p 2>/dev/null | tr -d '\0\n' | sed 's/[[:space:]]*$//'
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
        
        vendor_name=$(decode_vendor_correct $vendor_hex)
        
        echo "Производитель: $vendor_name (0x$vendor_hex)"
        echo "Product ID: 0x$product_hex"
        echo "Серийный номер (hex): $serial_hex"
        
        # Декодируем серийный номер
        serial_dec=$((16#$serial_hex))
        echo "Серийный номер (dec): $serial_dec"
        
        # Ищем дескрипторы
        model_name=""
        serial_string=""
        
        # Проверяем дескрипторы (начиная с позиции 108 в hex строке)
        for i in 0 1 2 3; do
            desc_start=$((109 + i * 36))
            if [ $((desc_start + 35)) -le ${#edid_data} ]; then
                desc=$(echo $edid_data | cut -c$desc_start-$((desc_start + 35)))
                desc_header=$(echo $desc | cut -c1-8)
                desc_type=$(echo $desc | cut -c9-10)
                
                if [ "$desc_header" = "00000000" ]; then
                    case $desc_type in
                        "fc")  # Monitor name
                            ascii_hex=$(echo $desc | cut -c19-36)
                            model_name=$(hex_to_ascii $ascii_hex)
                            ;;
                        "ff")  # Monitor serial number string
                            ascii_hex=$(echo $desc | cut -c19-36)
                            serial_string=$(hex_to_ascii $ascii_hex)
                            ;;
                    esac
                fi
            fi
        done
        
        [ -n "$model_name" ] && echo "Модель: $model_name"
        [ -n "$serial_string" ] && echo "Серийный номер (строка): $serial_string"
        
        # Создаем стабильные идентификаторы
        echo
        echo "СТАБИЛЬНЫЕ ИДЕНТИФИКАТОРЫ:"
        echo "1. По EDID: ${vendor_name}_${product_hex}_${serial_hex}"
        echo "2. По модели и серийнику: ${model_name}_${serial_string}"
        echo "3. Полный EDID hash: $(echo $edid_data | md5sum | cut -d' ' -f1)"
        
        # Connector ID (может меняться)
        connector_id=$(xrandr --verbose | sed -n "/$monitor/,/^[A-Z]/p" | grep "CONNECTOR_ID:" | awk '{print $2}')
        echo "4. Connector ID (нестабильный): $connector_id"
        
    else
        echo "EDID данные не найдены"
    fi
    echo "----------------------------------------"
done

echo
echo "=== ИТОГ ==="
echo "Для надежной идентификации мониторов в AwesomeWM используйте:"
echo "• EDID-based ID (vendor + product + serial) - самый надежный"
echo "• MD5 hash полного EDID - для абсолютной уверенности"
echo "• Избегайте привязки к именам портов типа DP-2-1"