#!/bin/bash

# Ubuntu Network Service Monitor
# Purpose: Check network services and detect failures

echo "========================================="
echo "      NETWORK SERVICE MONITOR"
echo "========================================="
echo "Date:::: $(date)"
echo " "

# Ubuntu VM IP address
SERVER="192.168.64.2"

#Service monitoring log files
LOG_FILE="$HOME/home-lab/logs/service-monitor.log"
ALERT_FILE="$HOME/home-lab/logs/service-alerts.log"

# Create the logs directory if needed
mkdir -p "$HOME/home-lab/logs"

# Check whether a TCP service is reachable
check_service() {
     SERVICE_NAME="$1"
     PORT="$2"

     echo "Checking $SERVICE_NAME on port $PORT. . ."

     if nc -z -w 3 "$SERVER" "$PORT" > /dev/null 2>&1; then
         echo "PASS: $SERVICE_NAME is reachable."
         echo "$(date '+%Y-%m-%d %H:%M:%S') | $SERVICE_NAME | PASS" >> "$LOG_FILE"
     else
         echo "FAIL: $SERVICE_NAME is unreachable."
         echo "$(date '+%Y-%m-%d %H:%M:%S') | $SERVICE_NAME | FAIL" >> "$LOG_FILE"
         echo "$(date '+%Y-%m-%d %H:%M:%S') | ALERT: $SERVICE_NAME on port $PORT is unreachable" >> "$ALERT_FILE"
     fi

     echo " "
}

# Test SSH connectivity
check_service "SSH" 22

# Test an unavailable TCP service
# check_service "Test Service" 9999
