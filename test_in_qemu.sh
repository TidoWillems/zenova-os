#!/bin/bash
# 🚀 Test-Script für QEMU-VM "ccn"

VM_NAME="ccn"

echo "🖥️ Starte Testlauf in QEMU-VM: $VM_NAME"

# Starte die VM falls sie nicht läuft
if ! pgrep -f "qemu-system" > /dev/null; then
    echo "⚡ Starte QEMU-VM..." | tee -a /var/log/qemu_test.log
    qemu-system-x86_64 -enable-kvm -m 2048 -hda /var/lib/libvirt/images/$VM_NAME.qcow2 -nographic &
    sleep 5
fi

# Führe einen Testlauf aus
ssh root@ccn "bash /mnt/data/stealth_boot_orchestrator_simplified.sh" | tee -a /var/log/qemu_test.log

echo "✅ Test abgeschlossen, Logs gespeichert." | tee -a /var/log/qemu_test.log
