#!/bin/bash
echo "🔄 Starte Recovery-Check..."
if [ -f /var/log/boot_errors.log ]; then
  echo "❌ Fehler im Boot-Prozess erkannt!"
  cat /var/log/boot_errors.log
else
  echo "✅ Kein Fehler erkannt!"
fi
