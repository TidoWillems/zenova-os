#!/bin/bash
echo "🔍 Analysiere Boot-Fehlerlogs..."
grep -i "error" /var/log/syslog | tail -n 10
echo "✅ Analyse abgeschlossen!"
