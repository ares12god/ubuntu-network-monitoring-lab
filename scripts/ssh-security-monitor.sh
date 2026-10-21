#!/bin/bash
# SSH Security Monitor
# Detects failed SSH password logins in the last few minutes, reports which
# source IPs they came from, and raises an alert past a threshold (a likely
# brute-force attempt). Runs from cron every 5 minutes.
#
# Needs read access to the auth log: run as root, or add your user to the
# "adm" group (sudo usermod -aG adm "$USER", then log in again).

# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

ALERT_LOG="$LOG_DIR/ssh-security-alerts.log"
CUTOFF_TIME=$(date -d "$SSH_WINDOW_SECONDS seconds ago" +%s)

# Collect "Failed password" lines from the monitoring window.
recent_failures() {
    if [[ -r "$AUTH_LOG" ]]; then
        local lines stamps
        lines=$(grep "Failed password" "$AUTH_LOG" | grep -v "COMMAND=")
        [[ -z "$lines" ]] && return 0

        # auth.log timestamps are either ISO 8601 (Ubuntu 23.10+,
        # "2026-10-21T14:25:01.123456-04:00") or classic syslog
        # ("Oct 21 14:25:01"). Convert all of them to epoch seconds with
        # a single `date -f -` call instead of one `date` per line.
        stamps=$(echo "$lines" \
            | awk '{ if ($1 ~ /^[0-9]/) print $1; else print $1 " " $2 " " $3 }' \
            | date -f - +%s)

        paste -d'|' <(echo "$stamps") <(echo "$lines") \
            | awk -F'|' -v cutoff="$CUTOFF_TIME" '$1 >= cutoff' \
            | cut -d'|' -f2-
    elif command -v journalctl > /dev/null; then
        # Systems without rsyslog keep auth events only in the journal
        journalctl -q -t sshd -t sshd-session --since "@$CUTOFF_TIME" -o short-iso 2>/dev/null \
            | grep "Failed password"
    else
        echo "ERROR: cannot read $AUTH_LOG (try: sudo usermod -aG adm \"\$USER\")" >&2
        exit 1
    fi
}

RECENT_FAILURES=$(recent_failures)
if [[ -z "$RECENT_FAILURES" ]]; then
    FAILED_ATTEMPTS=0
else
    FAILED_ATTEMPTS=$(echo "$RECENT_FAILURES" | wc -l)
fi

# "... Failed password for invalid user admin from 203.0.113.7 port 52144 ssh2"
SOURCE_IPS=$(echo "$RECENT_FAILURES" \
    | awk '{ for (i = 1; i < NF; i++) if ($i == "from") print $(i + 1) }' \
    | sort | uniq -c | sort -rn)

echo "===== SSH SECURITY MONITOR ====="
echo "Window: last $((SSH_WINDOW_SECONDS / 60)) minutes"
echo "Failed SSH login attempts: $FAILED_ATTEMPTS"

if [[ -n "$SOURCE_IPS" ]]; then
    echo "Failed SSH attempts by IP address:"
    echo "$SOURCE_IPS"
fi

if [[ "$FAILED_ATTEMPTS" -ge "$SSH_ALERT_THRESHOLD" ]]; then
    TOP_SOURCES=$(echo "$SOURCE_IPS" | awk '{printf "%s%s (%s)", sep, $2, $1; sep=", "}')
    echo "WARNING: Suspicious SSH login activity detected!"
    echo "$(timestamp) | ALERT | $FAILED_ATTEMPTS failed SSH logins in $((SSH_WINDOW_SECONDS / 60)) min from: $TOP_SOURCES" >> "$ALERT_LOG"
else
    echo "STATUS: Failed login count below alert threshold ($SSH_ALERT_THRESHOLD)."
fi
