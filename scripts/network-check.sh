#!/bin/bash
# Network Check
# Tests gateway reachability, Internet connectivity (packet loss + latency)
# and DNS resolution, diagnoses the likely fault, and records history for
# the uptime, performance, and dashboard reports. Runs from cron every 5 minutes.
#
# Simulate a full Internet outage (192.0.2.1 is a reserved TEST-NET address
# that never answers) without touching the real logs:
#   INTERNET_TARGET=192.0.2.1 LOG_DIR=/tmp/lab-test ./scripts/network-check.sh

# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

LOG="$LOG_DIR/network-check.log"
ALERT_LOG="$LOG_DIR/alerts.log"
ALERT_STATE_FILE="$LOG_DIR/alert-state.txt"
UPTIME_LOG="$LOG_DIR/uptime.log"
PERFORMANCE_LOG="$LOG_DIR/performance.csv"
NOW=$(timestamp)

touch "$ALERT_STATE_FILE"

log() {
    echo "$*" >> "$LOG"
}

# Alert de-duplication: an alert is written once when a problem starts, and a
# RECOVERED line is written once when it clears, instead of every 5 minutes.
raise_alert() {
    local alert_type="$1" message="$2"
    if ! grep -Fxq "$alert_type" "$ALERT_STATE_FILE"; then
        echo "$NOW | ALERT | $message" >> "$ALERT_LOG"
        echo "$alert_type" >> "$ALERT_STATE_FILE"
    fi
}

clear_alert() {
    local alert_type="$1" message="$2"
    if grep -Fxq "$alert_type" "$ALERT_STATE_FILE"; then
        sed -i "/^${alert_type}\$/d" "$ALERT_STATE_FILE"
        echo "$NOW | RECOVERED | $message" >> "$ALERT_LOG"
    fi
}

# Remove an alert state without logging a recovery (used when a worse
# condition supersedes it, e.g. packet loss turning into a full outage)
drop_alert() {
    sed -i "/^${1}\$/d" "$ALERT_STATE_FILE"
}

log "==========================================="
log "Network Check: $NOW"
log "==========================================="

# --- Gateway ----------------------------------------------------------------
GATEWAY=$(default_gateway)

if [[ -z "$GATEWAY" ]]; then
    GATEWAY_STATUS="OFFLINE"
    log "Gateway Status: ALERT - NO DEFAULT ROUTE"
    raise_alert "GATEWAY_UNREACHABLE" "NO DEFAULT GATEWAY CONFIGURED"
elif ping -c 2 -W 2 "$GATEWAY" > /dev/null 2>&1; then
    GATEWAY_STATUS="ONLINE"
    log "Gateway Status: ONLINE ($GATEWAY)"
    clear_alert "GATEWAY_UNREACHABLE" "GATEWAY $GATEWAY REACHABLE AGAIN"
else
    GATEWAY_STATUS="OFFLINE"
    log "Gateway Status: ALERT - $GATEWAY UNREACHABLE"
    raise_alert "GATEWAY_UNREACHABLE" "GATEWAY $GATEWAY UNREACHABLE"
fi

# --- Internet: packet loss and latency -----------------------------------
RESULT=$(ping -c 4 -W 2 "$INTERNET_TARGET" 2>&1)

# "4 packets transmitted, 3 received, 25% packet loss" -> 25
LOSS=$(echo "$RESULT" | sed -n 's/.* \([0-9.]*\)% packet loss.*/\1/p')
# "rtt min/avg/max/mdev = 10.1/12.3/15.0/1.2 ms" -> 12.3
AVG=$(echo "$RESULT" | awk -F/ '/^(rtt|round-trip)/ {print $5}')

# With no route at all, ping exits with an error ("Network is unreachable")
# and prints no statistics line. That is a total outage, not a parse failure.
if [[ -z "$LOSS" ]]; then
    LOSS=100
    log "Internet Ping Error: $(echo "$RESULT" | head -1)"
fi

log "Internet Packet Loss: $LOSS%"
log "Internet Average Latency: ${AVG:-N/A}${AVG:+ ms}"

if [[ "$LOSS" == "100" ]]; then
    INTERNET_STATUS="OFFLINE"
    log "Internet Status: ALERT - CONNECTION OFFLINE"
    drop_alert "PACKET_LOSS"
    drop_alert "HIGH_LATENCY"
    raise_alert "INTERNET_OFFLINE" "INTERNET CONNECTION OFFLINE ($INTERNET_TARGET)"
elif [[ "$LOSS" != "0" ]]; then
    INTERNET_STATUS="DEGRADED"
    log "Internet Status: ALERT - PACKET LOSS DETECTED"
    clear_alert "INTERNET_OFFLINE" "INTERNET CONNECTION RESTORED"
    clear_alert "HIGH_LATENCY" "LATENCY BACK TO NORMAL"
    raise_alert "PACKET_LOSS" "PACKET LOSS DETECTED - $LOSS%"
elif greater_than "$AVG" "$LATENCY_THRESHOLD_MS"; then
    INTERNET_STATUS="DEGRADED"
    log "Internet Status: ALERT - HIGH LATENCY"
    clear_alert "INTERNET_OFFLINE" "INTERNET CONNECTION RESTORED"
    clear_alert "PACKET_LOSS" "PACKET LOSS RESOLVED"
    raise_alert "HIGH_LATENCY" "HIGH LATENCY - $AVG ms"
else
    INTERNET_STATUS="ONLINE"
    log "Internet Status: ONLINE"
    clear_alert "INTERNET_OFFLINE" "INTERNET CONNECTION RESTORED"
    clear_alert "PACKET_LOSS" "PACKET LOSS RESOLVED"
    clear_alert "HIGH_LATENCY" "LATENCY BACK TO NORMAL"
fi

# --- DNS --------------------------------------------------------------------
if getent hosts "$DNS_TEST_HOST" > /dev/null; then
    DNS_STATUS="ONLINE"
    log "DNS Status: ONLINE"
    clear_alert "DNS_FAILURE" "DNS RESOLUTION WORKING AGAIN"
else
    DNS_STATUS="OFFLINE"
    log "DNS Status: ALERT - DNS RESOLUTION FAILED"
    raise_alert "DNS_FAILURE" "DNS RESOLUTION FAILED ($DNS_TEST_HOST)"
fi

# --- Automatic fault diagnosis ----------------------------------------------
# Checked from the bottom of the stack up: a gateway failure explains
# Internet and DNS failures, an Internet outage explains a DNS failure.
if [[ "$GATEWAY_STATUS" == "OFFLINE" && "$INTERNET_STATUS" == "OFFLINE" ]]; then
    log "Diagnosis: LOCAL NETWORK FAILURE - Gateway unreachable"
elif [[ "$GATEWAY_STATUS" == "OFFLINE" ]]; then
    log "Diagnosis: GATEWAY NOT ANSWERING PING - Internet still reachable (gateway may be dropping ICMP)"
elif [[ "$INTERNET_STATUS" == "OFFLINE" ]]; then
    log "Diagnosis: INTERNET OUTAGE - Gateway reachable but Internet unavailable"
elif [[ "$INTERNET_STATUS" == "DEGRADED" ]]; then
    log "Diagnosis: INTERNET PERFORMANCE ISSUE - Packet loss or high latency"
elif [[ "$DNS_STATUS" == "OFFLINE" ]]; then
    log "Diagnosis: DNS FAILURE - Unable to resolve domain names"
else
    log "Diagnosis: NETWORK HEALTHY - All checks passed"
fi

log "Check completed."
log " "

# --- History for reports and dashboard ---------------------------------------
# Uptime: DEGRADED still counts as available; only a full outage is downtime.
if [[ "$INTERNET_STATUS" == "OFFLINE" ]]; then
    echo "$NOW,OFFLINE" >> "$UPTIME_LOG"
else
    echo "$NOW,ONLINE" >> "$UPTIME_LOG"
fi

# Performance: timestamp, packet loss %, average latency ms (empty if no replies)
echo "$NOW,$LOSS,$AVG" >> "$PERFORMANCE_LOG"
