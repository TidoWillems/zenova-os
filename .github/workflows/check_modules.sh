#!/bin/bash
echo "🔍 Prüfe verfügbare Kernel-Module..."
lsmod | grep -i "kexec"
echo "✅ Treiberprüfung abgeschlossen!"
