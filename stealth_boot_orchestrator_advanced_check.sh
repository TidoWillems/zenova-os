#!/bin/bash

# 🚀 Stealth Boot Orchestrator
# Intelligenter Container für Boot-Management, Resilienz & Automation
logfile="/var/log/stealth_boot_orchestrator.log"
echo "🛡️ Stealth Boot Orchestrator gestartet..." | tee -a $logfile
echo "📌 Prüfe Kernel & Bootloader..." | tee -a $logfile

# 🛠 Korrigierte Kernel-Erkennung für bessere Stabilität
# 🛠 Vereinfachte Kernel-Erkennung für mehr Klarheit und Stabilität
latest_kernel=$(find /boot -name 'vmlinuz-*' | sort -V | tail -n 1)
latest_initrd=$(ls -t /boot/initrd.img-* | head -n 1)

detect_package_manager() {
    if command -v apt &>/dev/null; then echo "apt";
    elif command -v dnf &>/dev/null; then echo "dnf";
    elif command -v pacman &>/dev/null; then echo "pacman";
    elif command -v xbps-install &>/dev/null; then echo "xbps-install";
    else echo "❗ Kein unterstützter Paketmanager gefunden!"; exit 1;
    fi
}

detect_bootloader() {
    if [ -d "/boot/grub" ]; then echo "grub";
    elif [ -d "/boot/loader" ]; then echo "systemd-boot";
    elif [ -d "/EFI/BOOT" ]; then echo "rEFInd";
    else echo "❗ Kein unterstützter Bootloader gefunden!"; exit 1;
    fi
}

PKG_MANAGER=$(detect_package_manager)
BOOTLOADER=$(detect_bootloader)
echo "✅ Paketmanager: $PKG_MANAGER" | tee -a $logfile
echo "✅ Bootloader: $BOOTLOADER" | tee -a $logfile

echo "📌 Netzwerkcheck..." | tee -a $logfile
dns_servers=("8.8.8.8" "1.1.1.1" "9.9.9.9" "208.67.222.222")
network_ok=0

for dns in "${dns_servers[@]}"; do
    if ping -c 1 $dns &>/dev/null; then
        network_ok=1
        echo "✅ Netzwerk erkannt: $dns" | tee -a $logfile
        break
    fi
done

if [ "$network_ok" -eq 0 ]; then
    echo "❗ Kein Netzwerk! Fallback in Recovery-Modus..." | tee -a $logfile
    exec /bin/bash
fi

echo "📌 Prüfe Kernel-Dateien..." | tee -a $logfile
if [ ! -f "$latest_kernel" ] || [ ! -f "$latest_initrd" ]; then
    echo "❗ Kernel oder Initrd fehlen! Wechsle in Recovery-Shell..." | tee -a $logfile
    exec /bin/bash
fi

echo "✅ Lade Kernel: $latest_kernel" | tee -a $logfile
# 📌 Überprüfung & Installation fehlender Pakete
if ! command -v kexec &> /dev/null; then
    echo '⚠️ Kexec fehlt! Versuche automatische Installation...' | tee -a $logfile
    if [ "$PKG_MANAGER" == "apt" ]; then sudo apt update && sudo apt install -y kexec-tools; fi
    if [ "$PKG_MANAGER" == "dnf" ]; then sudo dnf install -y kexec-tools; fi
    if [ "$PKG_MANAGER" == "pacman" ]; then sudo pacman -S --noconfirm kexec-tools; fi
    if [ "$PKG_MANAGER" == "xbps-install" ]; then sudo xbps-install -Sy kexec-tools; fi
fi
# 📌 Überprüfung & Installation fehlender Pakete (mit automatischer Bestätigung)
if ! command -v kexec &> /dev/null; then
    echo '⚠️ Kexec fehlt! Versuche automatische Installation...' | tee -a $logfile
    if [ "$PKG_MANAGER" == "apt" ]; then sudo apt update && yes | sudo apt install -y kexec-tools; fi
    if [ "$PKG_MANAGER" == "dnf" ]; then yes | sudo dnf install -y kexec-tools; fi
    if [ "$PKG_MANAGER" == "pacman" ]; then yes | sudo pacman -S --noconfirm kexec-tools; fi
    if [ "$PKG_MANAGER" == "xbps-install" ]; then yes | sudo xbps-install -Sy kexec-tools; fi
fi
# 📌 Ermittlung des Root-Dateisystems
ROOT_PART=$(findmnt -n -o SOURCE /)
if [ -z "$ROOT_PART" ]; then
    echo '❗ Konnte Root-Partition nicht erkennen!' | tee -a $logfile
    exec /bin/bash
else
    echo '✅ Erkanntes Root-Device: $ROOT_PART' | tee -a $logfile
    BOOT_CMDLINE="quiet splash root=$ROOT_PART ro"
# 📌 Tiefere System-Prüfung vor Kexec
echo '🔍 Überprüfe Kernel-Kompatibilität mit Kexec...' | tee -a $logfile
if ! kexec --help &>/dev/null; then
    echo '❗ Kexec ist nicht korrekt installiert oder nicht kompatibel!' | tee -a $logfile
    exec /bin/bash
fi
# 📌 Prüfe ob Kernel benötigte Treiber enthält
MISSING_MODULES=0
for module in ext4 vfat xfs btrfs; do
    if ! lsmod | grep -q $module; then
        echo '⚠️ Fehlender Treiber erkannt: $module' | tee -a $logfile
        MISSING_MODULES=1
    fi
done
if [ $MISSING_MODULES -eq 1 ]; then
    echo '❗ Kritische Kernel-Module fehlen! Abbruch...' | tee -a $logfile
    exec /bin/bash
fi
# 📌 Letzte Boot-Befehlsprüfung
echo '✅ Alle Checks bestanden. Starte Kexec... ' | tee -a $logfile
    sudo kexec --load "$latest_kernel" --initrd="$latest_initrd" --command-line="$BOOT_CMDLINE"
fi
( sleep 10 && echo "❗ Kexec hängt! Abbruch..." | tee -a $logfile && exec /bin/bash ) &
sudo kexec -e
