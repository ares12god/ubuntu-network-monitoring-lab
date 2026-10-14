#!/bin/bash

# System Health Monitor
# Monitors CPU, memory, and disk usage
# Ubuntu Network Monitoring Home Lab

CPU_THRESHOLD=80
MEMORY_THRESHOLD=80
DISK_THRESHOLD=85

read -r _ user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat
TOTAL1=$((user + nice + system + idle + iowait + irq + softirq + steal))
IDLE1=$((idle + iowait))
sleep 1
read -r _ user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat
TOTAL2=$((user + nice + system + idle + iowait + irq + softirq + steal))
IDLE2=$((idle + iowait))
CPU_USAGE=$((100 * ((TOTAL2 -TOTAL1) - (IDLE2 -IDLE1)) / (TOTAL2 - TOTAL1)))

MEMORY_USAGE=$(free | awk '/^Mem:/ {printf "%.0f", ($2-$7)/$2*100}')

DISK_USAGE=$(df / | awk 'NR==2 {gsub("%", " ",$5); print $5}')

echo "===== SYSTEM HEALTH REPORT ====="
echo "CPU Usage: $CPU_USAGE%"
echo "Memory Usage: $MEMORY_USAGE%"
echo "Disk Usage: $DISK_USAGE%"

if [ "$CPU_USAGE" -ge "$CPU_THRESHOLD" ]; then
    echo "WARNING: High CPU usage detected!"
else
    echo "CPU Status: Normal"
fi

if [ "$MEMORY_USAGE" -ge "$MEMORY_THRESHOLD" ]; then
    echo "WARNING: High memory usage detected!"
else
    echo "Memory Status: Normal"
fi

if [ "$DISK_USAGE" -ge "$DISK_THRESHOLD" ]; then
    echo "WARNING: High disk usage detected!"
else
    echo "Disk Status: Normal"
fi

