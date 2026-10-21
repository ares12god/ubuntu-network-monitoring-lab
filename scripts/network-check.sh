#!/bin/bash

LOG="$HOME/home-lab/logs/network-check.log"
ALERT_LOG="$HOME/home-lab/logs/alerts.log"
ALERT_STATE_FILE="$HOME/home-lab/logs/alert-state.txt"
touch "$ALERT_STATE_FILE"
log_alert() {
    local alert_type="$1"
    local alert_message="$2"

    if ! grep -Fxq "$alert_type" "$ALERT_STATE_FILE"; then
        echo "ALERT: $(date) - $alert_message" >> "$ALERT_LOG"
        echo "$alert_type" >> "$ALERT_STATE_FILE"
    fi
}
UPTIME_LOG="$HOME/home-lab/logs/uptime.log"
PERFORMANCE_LOG="$HOME/home-lab/logs/performance.csv"

echo "===========================================" >> "$LOG"
echo "Network Check: $(date)" >> "$LOG"
echo "===========================================" >> "$LOG"

# Gateway monitoring
GATEWAY=$(ip route | awk '/^default/ {print $3; exit}')

if ping -c 2 -W 2 "$GATEWAY" > /dev/null 2>&1; then
   GATEWAY_STATUS="Online"
   sed -i '/^GATEWAY_UNREACHABLE$/d' "$ALERT_STATE_FILE"
   echo "Gateway Status: ONLINE" >> "$LOG"
else
   GATEWAY_STATUS="Offline"
   echo "Gateway Status: ALERT - UNREACHABLE" >> "$LOG"
   log_alert "GATEWAY_UNREACHABLE" "GATEWAY UNREACHABLE"
fi

RESULT=$(ping -c 4 1.1.1.1)

LOSS=$(echo "$RESULT" | grep "packet loss" | sed 's/.*,\s*\([0-9]*\)% packet loss.*/\1/')
AVG=$(echo "$RESULT" | grep "rtt" | sed 's/.*= [0-9.]*\/\([0-9.]*\)\/.*/\1/')

echo "Internet Packet Loss: $LOSS%" >> "$LOG"

if [[ -z "$AVG" ]]; then
    echo "Internet Average Latency: N/A" >> "$LOG"
else
    echo "Internet Average Latency: $AVG ms" >> "$LOG"
fi

if [[ "$LOSS" == "100" ]]; then
    INTERNET_STATUS="OFFLINE"
    echo "Internet Status: ALERT - CONNECTION OFFLINE" >> "$LOG"
    log_alert "INTERNET_OFFLINE" "INTERNET CONNECTION OFFLINE"
    sed -i '/^PACKET_LOSS$/d' "$ALERT_STATE_FILE"
    sed -i '/^HIGH_LATENCY$/d' "$ALERT_STATE_FILE"
elif [[ "$LOSS" != "0" ]]; then
    sed -i '/^INTERNET_OFFLINE$/d' "$ALERT_STATE_FILE"
    INTERNET_STATUS="DEGRADED"
    echo "Internet Status: ALERT - PACKET LOSS DETECTED" >> "$LOG"
    sed -i '/^HIGH_LATENCY$/d' "$ALERT_STATE_FILE"
    log_alert "PACKET_LOSS" "PACKET LOSS DETECTED"
elif (( $(echo "$AVG > 100" | bc -l) )); then
    sed -i '/^INTERNET_OFFLINE$/d' "$ALERT_STATE_FILE"
    sed -i '/^PACKET_LOSS$/d' "$ALERT_STATE_FILE"
    INTERNET_STATUS="DEGRADED"
    echo "Internet Status: ALERT - HIGH LATENCY" >> "$LOG"
    log_alert "HIGH_LATENCY" "HIGH LATENCY"
else
    INTERNET_STATUS="ONLINE"
    sed -i '/^HIGH_LATENCY$/d' "$ALERT_STATE_FILE"
    sed -i '/^PACKET_LOSS$/d' "$ALERT_STATE_FILE"
    sed -i '/^INTERNET_OFFLINE$/d' "$ALERT_STATE_FILE"
    echo "Internet Status: ONLINE" >> "$LOG"
fi

if getent hosts google.com > /dev/null; then
   DNS_STATUS="ONLINE"
   sed -i '/^DNS_FAILURE$/d' "$ALERT_STATE_FILE"
   echo "DNS Status: ONLINE" >> "$LOG"
else
   DNS_STATUS="OFFLINE"
   echo "DNS Status: ALERT - DNS RESOLUTION FAILED" >> "$LOG"
   log_alert "DNS_FAILURE" "DNS RESOLUTION FAILED"
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
elif [[ "$DNS_STATUS" == "OFFLINE" ]]; then
   echo "Diagnosis: DNS FAILURE - Unable to resolve domain names" >> "$LOG"
else
   echo "Diagnosis: NETWORK HEALTHY - All checks passed" >> "$LOG"
fi

# Internet uptime tracking
if [[ "$INTERNET_STATUS" == "OFFLINE" ]]; then
   echo "$(date '+%Y-%m-%d %H:%M:%S'),OFFLINE" >> "$UPTIME_LOG"
else
   echo "$(date '+%Y-%m-%d %H:%M:%S'),ONLINE" >> "$UPTIME_LOG"
fi

# Historical network performance tracking
echo "$(date '+%Y-%m-%d %H:%M:%S'),${LOSS},${AVG}" >> "$PERFORMANCE_LOG"
