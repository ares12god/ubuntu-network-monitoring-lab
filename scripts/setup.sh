#!/bin/bash
# Lab setup
# Checks dependencies, makes the scripts executable, creates the log folder,
# and prints (or installs) the cron schedule for this clone's location.
#
# Usage:
#   ./scripts/setup.sh                  # check and print the cron lines
#   ./scripts/setup.sh --install-cron   # also add them to your crontab

# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

echo "Lab directory: $LAB_DIR"
echo " "
echo "Checking dependencies. . ."

MISSING=0
check() {
    local cmd="$1" package="$2"
    if command -v "$cmd" > /dev/null; then
        echo "  OK       $cmd"
    else
        echo "  MISSING  $cmd   (sudo apt install $package)"
        MISSING=1
    fi
}
check ip        iproute2
check ping      iputils-ping
check getent    libc-bin
check nc        netcat-openbsd
check ss        iproute2
check tracepath iputils-tracepath
check nslookup  dnsutils
check python3   python3

if python3 -c "import matplotlib" 2> /dev/null; then
    echo "  OK       matplotlib"
else
    echo "  MISSING  matplotlib   (sudo apt install python3-matplotlib)"
    MISSING=1
fi

chmod +x "$LAB_DIR"/scripts/*.sh
mkdir -p "$LOG_DIR" "$REPORT_DIR"

CRON_LINES="# ubuntu-network-monitoring-lab
*/5 * * * * $LAB_DIR/scripts/network-check.sh
*/5 * * * * $LAB_DIR/scripts/service-monitor.sh > /dev/null
*/5 * * * * $LAB_DIR/scripts/system-health-monitor.sh > /dev/null
*/5 * * * * $LAB_DIR/scripts/ssh-security-monitor.sh > /dev/null
1-56/5 * * * * python3 $LAB_DIR/scripts/network-dashboard.py --days 7 > /dev/null
55 23 * * * $LAB_DIR/scripts/daily-report.sh > /dev/null"

echo " "
echo "Cron schedule for this clone:"
echo " "
echo "$CRON_LINES"
echo " "

if [[ "${1:-}" == "--install-cron" ]]; then
    if crontab -l 2> /dev/null | grep -qF "$LAB_DIR/scripts/network-check.sh"; then
        echo "Cron jobs already installed - leaving your crontab unchanged."
    else
        (crontab -l 2> /dev/null; echo "$CRON_LINES") | crontab -
        echo "Cron jobs installed. Review with: crontab -l"
    fi
else
    echo "To install: ./scripts/setup.sh --install-cron  (or paste into: crontab -e)"
fi

if [[ "$MISSING" -ne 0 ]]; then
    echo " "
    echo "Install the missing packages above, then re-run setup."
fi
