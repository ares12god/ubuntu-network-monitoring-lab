#!/bin/bash
# Internet Availability Report
# Summarizes every check recorded in logs/uptime.log by network-check.sh.

# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

UPTIME_LOG="$LOG_DIR/uptime.log"

if [[ ! -s "$UPTIME_LOG" ]]; then
    echo "No uptime data available ($UPTIME_LOG). Run network-check.sh first."
    exit 0
fi

echo "===== INTERNET AVAILABILITY REPORT ====="
awk -F, '
{
    total++
    if (first == "" || $1 < first) first = $1
    if ($1 > last) last = $1
    if ($2 == "ONLINE") online++
}
END {
    printf "Period: %s to %s\n", first, last
    printf "Total Checks: %d\n", total
    printf "Successful Checks: %d\n", online
    printf "Failed Checks: %d\n", total - online
    printf "Internet Availability: %.2f%%\n", online / total * 100
}' "$UPTIME_LOG"
