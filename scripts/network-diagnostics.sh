#!/bin/bash

# Ubuntu Network Diagnostic Toolkit
# Purpose: Troubleshoot network connectivity issues

echo "============================================="
echo "       NETWORK DIAGNOSTIC TOOLKIT"
echo "============================================="
echo "Date: $(date)"
echo " "

# Identify the default gateway
check_gateway() {
   echo "Checking default gateway. . ."

   GATEWAY=$(ip route | awk '/^default/ {print $3; exit}')

   if [ -n "GATEWAY" ]; then
       echo "Default Gateway: $GATEWAY"
   else
       echo "ERROR: No default gateway found."
   fi

   echo " "
}

# Test connectivity to the default gateway
test_gateway() {
    echo "Testing gateway connectivity. . ."

    if [ -z "$GATEWAY" ]; then
        echo "FAIL: No default gateway configured."
    elif ping -c 4 -W 2 "$GATEWAY" > /dev/null 2>&1; then
        echo "PASS: Gateway $GATEWAY is reachable."
    else
        echo "FAIL: Gateway $GATEWAY is unreachable."
    fi

    echo " "
}

# Test Internet connectivity
test_internet() {
    echo "Testing Internet connectivity. . ."

    if ping -c 4 -W 2 8.8.8.8 > /dev/null 2>&1; then
        echo "PASS: Internet connection is working."
    else
        echo "FAIL: Cannot reach external IP 8.8.8.8."
    fi

    echo " "
}

# Test DNS resolution
test_dns() {
    echo "Testing DNS resolution. . ."

    if nslookup google.com > /dev/null 2>&1; then
        echo "PASS: DNS resolution is working."
    else
        echo "FAIL: DNS resolution failed."
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
    echo "Tracing network path to 8.8.8.8. . ."
    echo " "

    tracepath -m 15 8.8.8.8

    echo " "
}

# Display listening network ports
check_ports() {
    echo "Checking listening network ports. . ."
    echo " "

    ss -tuln

    echo " "
}

# Run all network diagnostics
check_gateway
test_gateway
test_internet
test_dns
check_routes
check_path
check_ports

echo "==========================================="
echo "           DIAGNOSTICS COMPLETE"
echo "==========================================="
