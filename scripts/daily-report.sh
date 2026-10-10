#!/bin/bash

# Daily Network Health Report
REPORT_DIR="$HOME/home-lab/reports"
DATE=$(date +%Y-%m-%d)
REPORT="$REPORT_DIR/network-report-$DATE.txt"

mkdir -p "$REPORT_DIR"
: > "$REPORT"

echo "====================================" > "%REPORT"
echo "DAILY NETWORK HEALTH REPORT" >> "$REPORT"
echo "Date: $DATE" >> "$REPORT"
echo "====================================" >> "$REPORT"

echo " " >> "$REPORT"
echo "INTERNET AVAILABILITY SUMMARY" >> "$REPORT"
echo "------------------------------------" >> "$REPORT"

awk -F, -v day="$DATE" '
$1 ~ "^" day {
    total++
    if ($2 == "ONLINE") online++
}
END {
    printf "Total Checks: %d\n", total
    printf "Successful Checks: %d\n", online
    printf "Failed Checks: %d\n", total-online
    if (total > 0)
        printf "Internet Availability: %.2f%%\n", online/total*100
    else
        print "Internet Availability: N/A"
}' "$HOME/home-lab/logs/uptime.log" >> "$REPORT"

echo " " >> "$REPORT"
echo "NETWORK ALERT SUMMARY" >> "$REPORT"
echo "------------------------------------" >> "$REPORT"

ALERT_LOG="$HOME/home-lab/logs/alerts.log"

if [[ -f "$ALERT_LOG" ]]; then
      ALERT_COUNT=$(grep -c "$(date '+%a %b %-d ')" "$ALERT_LOG" || true)
      echo "Alerts Today: $ALERT_COUNT" >> "$REPORT"
else
      echo "Alerts Today: 0" >> "$REPORT"
fi
