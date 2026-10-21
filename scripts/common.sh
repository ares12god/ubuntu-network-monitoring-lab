#!/bin/bash
# Shared settings and helpers for every script in this lab.
# Sourced, not executed:  source "$(dirname "$0")/common.sh"
#
# Every setting can be overridden from the environment, e.g.
#   INTERNET_TARGET=192.0.2.1 LOG_DIR=/tmp/lab-test ./scripts/network-check.sh

# Repository root, worked out from this file's location so the lab runs
# from wherever it is cloned (no hardcoded home directory).
LAB_DIR="${LAB_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
LOG_DIR="${LOG_DIR:-$LAB_DIR/logs}"
REPORT_DIR="${REPORT_DIR:-$LAB_DIR/reports/generated}"

# Network check targets and thresholds
INTERNET_TARGET="${INTERNET_TARGET:-1.1.1.1}"   # host pinged to test Internet reachability
DNS_TEST_HOST="${DNS_TEST_HOST:-google.com}"    # name resolved to test DNS
LATENCY_THRESHOLD_MS="${LATENCY_THRESHOLD_MS:-100}"

# System health thresholds (percent)
CPU_THRESHOLD="${CPU_THRESHOLD:-80}"
MEMORY_THRESHOLD="${MEMORY_THRESHOLD:-80}"
DISK_THRESHOLD="${DISK_THRESHOLD:-85}"

# SSH security monitor
AUTH_LOG="${AUTH_LOG:-/var/log/auth.log}"
SSH_WINDOW_SECONDS="${SSH_WINDOW_SECONDS:-300}"
SSH_ALERT_THRESHOLD="${SSH_ALERT_THRESHOLD:-3}"

# TCP services checked by service-monitor.sh, as NAME:PORT pairs
SERVICES="${SERVICES:-SSH:22}"

mkdir -p "$LOG_DIR"

# ISO-style timestamp used in every log line. Sortable, locale-independent,
# and easy to filter by day with grep "^2026-10-09".
timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Default gateway from the routing table (empty if there is none)
default_gateway() {
    ip route 2>/dev/null | awk '/^default/ {print $3; exit}'
}

# Succeeds if $1 > $2, comparing as decimal numbers (no bc needed)
greater_than() {
    awk -v a="$1" -v b="$2" 'BEGIN { exit !(a + 0 > b + 0) }'
}
