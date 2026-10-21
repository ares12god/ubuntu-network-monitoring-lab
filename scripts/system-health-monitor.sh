#!/bin/bash
# System Health Monitor
# Measures CPU, memory, and disk usage, records each reading, and logs an
# alert when a threshold is crossed. Runs from cron every 5 minutes.

# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

HEALTH_LOG="$LOG_DIR/system-health.log"
ALERT_LOG="$LOG_DIR/system-alerts.log"

# CPU: sample the counters in /proc/stat one second apart. Usage is the share
# of elapsed CPU time that was not idle or waiting on I/O.
read_cpu() {
    local _ user nice system idle iowait irq softirq steal
    read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
    echo "$((user + nice + system + idle + iowait + irq + softirq + steal)) $((idle + iowait))"
}
read -r TOTAL1 IDLE1 <<< "$(read_cpu)"
sleep 1
read -r TOTAL2 IDLE2 <<< "$(read_cpu)"
CPU_USAGE=$((100 * ((TOTAL2 - TOTAL1) - (IDLE2 - IDLE1)) / (TOTAL2 - TOTAL1)))

# Memory: (total - available) / total. "available" counts reclaimable cache,
# so this reflects real memory pressure rather than cache usage.
MEMORY_USAGE=$(free | awk '/^Mem:/ {printf "%.0f", ($2 - $7) / $2 * 100}')

# Disk: usage of the root filesystem, without the % sign
DISK_USAGE=$(df --output=pcent / | tail -1 | tr -dc '0-9')

echo "===== SYSTEM HEALTH REPORT ====="
echo "CPU Usage: $CPU_USAGE%"
echo "Memory Usage: $MEMORY_USAGE%"
echo "Disk Usage: $DISK_USAGE%"

echo "$(timestamp) | CPU $CPU_USAGE% | Memory $MEMORY_USAGE% | Disk $DISK_USAGE%" >> "$HEALTH_LOG"

check_threshold() {
    local name="$1" usage="$2" threshold="$3"
    if [[ "$usage" -ge "$threshold" ]]; then
        echo "WARNING: High $name usage detected!"
        echo "$(timestamp) | ALERT | $name usage at $usage% (threshold $threshold%)" >> "$ALERT_LOG"
    else
        echo "$name Status: Normal"
    fi
}

check_threshold "CPU" "$CPU_USAGE" "$CPU_THRESHOLD"
check_threshold "Memory" "$MEMORY_USAGE" "$MEMORY_THRESHOLD"
check_threshold "Disk" "$DISK_USAGE" "$DISK_THRESHOLD"
