#!/bin/bash

LOG="$HOME/home-lab/logs/network-check.log"
ALERT_LOG="$HOME/home-lab/logs/alerts.log"

echo "===========================================" >> "$LOG"
echo "Network Check: $(date)" >> "$LOG"
echo "===========================================" >> "$LOG"

# Gateway monitoring
GATEWAY=$(ip route | awk '/^default/ {print $3; exit}')

if ping -c 2 -W 2 "$GATEWAY" > /dev/null 2>&1; then
   GATEWAY_STATUS="Online"
   echo "Gateway Status: ONLINE" >> "$LOG"
else
   GATEWAY_STATUS="Offline"
   echo "Gateway Status: ALERT - UNREACHABLE" >> "$LOG"
   echo "ALERT: $(date) - GATEWAY UNREACHABLE" >> "$ALERT_LOG"
fi

RESULT=$(ping -c 4 1.1.1.1)

LOSS=$(echo "$RESULT" | grep "packet loss" | sed 's/.*,\s*\([0-9]*\)% packet loss.*/\1/')
AVG=$(echo "$RESULT" | grep "rtt" | sed 's/.*= [0-9.]*\/\([0-9.]*\)\/.*/\1/')

echo "Internet Packet Loss: $LOSS%" >> "$LOG"

if [[ -z "AVG" ]]; then
    echo "Internet Average Latency: N/A" >> "$LOG"
else
    echo "Internet Average Latency: $AVG ms" >> "$LOG"
fi

if [[ "$LOSS" == "100" ]]; then
    INTERNET_STATUS="OFFLINE"
    echo "Internet Status: ALERT - CONNECTION OFFLINE" >> "$LOG"
    echo "ALERT: $(date) - INTERNET CONNECTION OFFLINE" >> "ALERT_LOG"
elif [[ "$LOSS" != "0" ]]; then
    INTERNET_STATUS="DEGRADED"
    echo "Internet Status: ALERT - PACKET LOSS DETECTED" >> "$LOG"
    echo "ALERT: $(date) - PACKET LOSS DETECTED - $LOSS%" >> "$ALERT_LOG"
elif (( $(echo "$AVG > 100" | bc -l) )); then
    INTERNET_STATUS="DEGRADED"
    echo "Internet Status: ALERT - HIGH LATENCY" >> "$LOG"
    echo "ALERT: $(date) - HIGH LATENCY - $AVG ms" >> "$ALERT_LOG"
else
    INTERNET_STATUS="ONLINE"
    echo "Internet Status: ONLINE" >> "$LOG"
fi

if getent hosts google.com > /dev/null; then
   DNS_STATUS="ONLINE"
   echo "DNS Status: ONLINE" >> "$LOG"
else
   DNS_STATUS="OFFLINE"
   echo "DNS Status: ALERT - DNS RESOLUTION FAILED" >> "$LOG"
   echo "ALERT: $(date) - DNS RESOLUTION FAILED" >> "$ALERT_LOG"
fi

echo "Check completed." >> "$LOG"
echo " " >> "$LOG"

# Automatic network fault diagnosis
if [[ "$GATEWAY_STATUS" == "OFFLINE" ]]; then
   echo "Diagnosis: LOCAL NETWORK FAILURE - Gatway unreachable" >> "$LOG"
elif [[ "$INTERNET_STATUS" == "OFFLINE" ]]; then
   echo "Diagnosis: INTERNET OUTAGE - Gateway reachable but Internet unavailable" >> "$LOG"
elif [[ "$INTERNET_STATUS" == "DEGRADED" ]]; then
   echo "Diagnosis: INTERNET PERFORMANCE ISSUE - Packet loss or high latency" >> "$LOG"
elif [[ "DNS_STATUS" == "OFFLINE" ]]; then
   echo "Diagnosis: DNS FAILURE - Unable to resolve domain names" >> "$LOG"
else
   echo "Diagnosis: NETWORK HEALTHY - All checks passed" >> "$LOG"
fi
