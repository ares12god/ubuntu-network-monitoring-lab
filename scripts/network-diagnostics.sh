#!/bin/bash
# Network Diagnostic Toolkit
# Interactive, on-demand troubleshooting: walks the network stack from the
# local gateway out to the Internet and DNS, then shows routes, the path
# to an external host, and listening ports.
#
# Exit status is the number of failed tests (0 = everything passed).

# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

TRACE_TARGET="${TRACE_TARGET:-8.8.8.8}"
FAILURES=0

pass() { echo "PASS: $*"; }
fail() { echo "FAIL: $*"; FAILURES=$((FAILURES + 1)); }

echo "============================================="
echo "       NETWORK DIAGNOSTIC TOOLKIT"
echo "============================================="
echo "Date: $(timestamp)"
echo " "

# Identify the default gateway
check_gateway() {
    echo "Checking default gateway. . ."
    GATEWAY=$(default_gateway)

    if [[ -n "$GATEWAY" ]]; then
        echo "Default Gateway: $GATEWAY"
    else
        echo "ERROR: No default gateway found."
    fi
    echo " "
}

# Test connectivity to the default gateway
test_gateway() {
    echo "Testing gateway connectivity. . ."

    if [[ -z "$GATEWAY" ]]; then
        fail "No default gateway configured."
    elif ping -c 4 -W 2 "$GATEWAY" > /dev/null 2>&1; then
        pass "Gateway $GATEWAY is reachable."
    else
        fail "Gateway $GATEWAY is unreachable."
    fi
    echo " "
}

# Test Internet connectivity by IP (rules out DNS)
test_internet() {
    echo "Testing Internet connectivity. . ."

    if ping -c 4 -W 2 "$INTERNET_TARGET" > /dev/null 2>&1; then
        pass "Internet connection is working ($INTERNET_TARGET reachable)."
    else
        fail "Cannot reach external IP $INTERNET_TARGET."
    fi
    echo " "
}

# Test DNS resolution (nslookup if installed, otherwise the system resolver)
test_dns() {
    echo "Testing DNS resolution. . ."

    if command -v nslookup > /dev/null; then
        lookup() { nslookup "$1" > /dev/null 2>&1; }
    else
        lookup() { getent hosts "$1" > /dev/null; }
    fi

    if lookup "$DNS_TEST_HOST"; then
        pass "DNS resolution is working ($DNS_TEST_HOST)."
    else
        fail "DNS resolution failed for $DNS_TEST_HOST."
    fi
    echo " "
}

# Display network routing information
check_routes() {
    echo "Checking network routing table. . ."
    echo " "
    ip route
    echo " "
}

# Trace the network path to an external server
check_path() {
    echo "Tracing network path to $TRACE_TARGET. . ."
    echo " "
    if command -v tracepath > /dev/null; then
        tracepath -m 15 "$TRACE_TARGET"
    else
        echo "tracepath not installed (sudo apt install iputils-tracepath)"
    fi
    echo " "
}

# Display listening network ports
check_ports() {
    echo "Checking listening network ports. . ."
    echo " "
    ss -tuln
    echo " "
}

check_gateway
test_gateway
test_internet
test_dns
check_routes
check_path
check_ports

echo "==========================================="
if [[ "$FAILURES" -eq 0 ]]; then
    echo "   DIAGNOSTICS COMPLETE - ALL TESTS PASSED"
else
    echo "   DIAGNOSTICS COMPLETE - $FAILURES TEST(S) FAILED"
fi
echo "==========================================="

exit "$FAILURES"
