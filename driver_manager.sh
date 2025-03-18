#!/bin/bash
# 🚀 Dynamisches Treiber-Management für universelle Kompatibilität

logfile="/var/log/driver_manager.log"

echo "🖥️ Treiber-Manager gestartet..." | tee -a $logfile

# Erkennen von benötigten Treibern
hardware_info=$(lspci | awk '{print $1}')

for device in $hardware_info; do
    driver=$(lspci -k | grep -A 2 "$device" | grep "Kernel driver in use" | awk -F': ' '{print $2}')
    if [ -z "$driver" ]; then
        echo "⚠️ Fehlender Treiber für $device erkannt!" | tee -a $logfile
        echo "🔄 Versuche Treiber automatisch zu laden..." | tee -a $logfile
        modprobe $device 2>/dev/null && echo "✅ Treiber $device geladen." | tee -a $logfile
    else
        echo "✔️ Treiber für $device bereits aktiv: $driver" | tee -a $logfile
    fi
done

echo "✅ Treiber-Scan abgeschlossen." | tee -a $logfile
