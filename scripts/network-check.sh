#!/bin/bash

LOG="$HOME/home-lab/logs/network-check.log"
ALERT_LOG="$HOME/home-lab/logs/alerts.log"

echo "===========================================" >> "$LOG"
echo "Network Check: $(date)" >> "$LOG"
echo "===========================================" >> "$LOG"

# Gateway monitoring
GATEWAY=$(ip route | awk '/^default/ {print $3; exit}')

if ping -c 2 -W 2 "$GATEWAY" > /dev/null 2>&1; then
   echo "Gateway Status: ONLINE" >> "$LOG"
else
   echo "Gateway Status: ALERT - UNREACHABLE" >> "$LOG"
   echo "ALERT: $(date) - GATEWAY UNREACHABLE" >> "$ALERT_LOG"
fi

RESULT=$(ping -c 4 1.1.1.1)

LOSS=$(echo "$RESULT" | grep "packet loss" | sed 's/.*,\s*\([0-9]*\)% packet loss.*/\1/')
AVG=$(echo "$RESULT" | grep "rtt" | sed 's/.*= [0-9.]*\/\([0-9.]*\)\/.*/\1/')

echo "Internet Packet Loss: $LOSS%" >> "$LOG"
echo "Internet Average Latency: $AVG ms" >> "$LOG"

if [[ "$LOSS" != "0" ]]; then
    echo "Internet Status: ALERT - PACKET LOSS DETECTED" >> "$LOG"
    echo "ALERT: $(date) - PACKET LOSS DETECTED - $LOSS%" >> "$ALERT_LOG"
elif (( $(echo "$AVG > 100" | bc -l) )); then
    echo "Internet Status: ALERT - HIGH LATENCY" >> "$LOG"
    echo "ALERT: $(date) - HIGH LATENCY - $AVG ms" >> "$ALERT_LOG"
else
    echo "Internet Status: ONLINE" >> "$LOG"
fi

if getent hosts google.com > /dev/null; then
   echo "DNS Status: ONLINE" >> "$LOG"
else
   echo "DNS Status: ALERT - DNS RESOLUTION FAILED" >> "$LOG"
   echo "ALERT: $(date) - DNS RESOLUTION FAILED" >> "$ALERT_LOG"
fi

echo "Check completed." >> "$LOG"
echo " " >> "$LOG"
