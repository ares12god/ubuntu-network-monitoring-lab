#!/bin/bash
# Network Service Monitor
# Checks that TCP services are accepting connections and records failures.
#
# Services come from SERVICES in common.sh (NAME:PORT pairs), e.g.
#   SERVICES="SSH:22 HTTP:80" ./scripts/service-monitor.sh

# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

LOG_FILE="$LOG_DIR/service-monitor.log"
ALERT_FILE="$LOG_DIR/service-alerts.log"

# Host to test: this machine's primary IP, so the check goes through the
# network stack and firewall rather than loopback. Override with SERVICE_HOST.
SERVER="${SERVICE_HOST:-$(hostname -I 2>/dev/null | awk '{print $1}')}"
SERVER="${SERVER:-127.0.0.1}"

echo "========================================="
echo "      NETWORK SERVICE MONITOR"
echo "========================================="
echo "Date: $(timestamp)"
echo "Host: $SERVER"
echo " "

# Check whether a TCP service is reachable
check_service() {
    local service_name="$1" port="$2"

    echo "Checking $service_name on port $port. . ."

    if nc -z -w 3 "$SERVER" "$port" > /dev/null 2>&1; then
        echo "PASS: $service_name is reachable."
        echo "$(timestamp) | $service_name | $SERVER:$port | PASS" >> "$LOG_FILE"
    else
        echo "FAIL: $service_name is unreachable."
        echo "$(timestamp) | $service_name | $SERVER:$port | FAIL" >> "$LOG_FILE"
        echo "$(timestamp) | ALERT | $service_name on $SERVER:$port is unreachable" >> "$ALERT_FILE"
    fi
    echo " "
}

for service in $SERVICES; do
    check_service "${service%%:*}" "${service##*:}"
done
