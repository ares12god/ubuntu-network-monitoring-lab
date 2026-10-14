#!/bin/bash

# SSH Security Monitor
# Detects failed SSH login attempts
# Part of the Ubuntu Network Monitoring Home Lab

LOG_FILE="/var/log/auth.log"
MONITOR_WINDOW=300
CUTOFF_TIME=$(date -d "$MONITOR_WINDOW seconds ago" +%s)
ALERT_LOG="/home/c-money12/home-lab/logs/ssh-security-alerts.log"

RECENT_FAILURES=$(grep "Failed password" "$LOG_FILE" | grep -v "COMMAND=" | awk -v cutoff="$CUTOFF_TIME" '{cmd="date -d \" " $1 "\" +%s 2>/dev/null"; cmd | getline timestamp; close(cmd); if(timestamp >= cutoff) print}')

FAILED_ATTEMPTS=$(printf '%s\n' "$RECENT_FAILURES" | grep -c "Failed password")

echo "Failed SSH login attempts: $FAILED_ATTEMPTS"

echo "Failed SSH attempts by IP address:"
printf '%s\n' "$RECENT_FAILURES" | awk '{for(i=1;i<=NF;i++) if($i=="from") print $(i+1)}' | sort | uniq -c

ALERT_THRESHOLD=3

if [ "$FAILED_ATTEMPTS" -ge "$ALERT_THRESHOLD" ]; then
    echo "WARNING: Suspicious SSH login activity detected!"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - WARNING: $FAILED_ATTEMPTS failed SSH login attempts detected" >> "$ALERT_LOG"
else
    echo "STATUS: Failed login count below alert threshold."
fi

