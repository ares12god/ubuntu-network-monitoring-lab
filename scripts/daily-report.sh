#!/bin/bash
# Daily Network Health Report
# Summarizes one day of Internet availability, alerts, and performance.
#
# Usage:
#   ./scripts/daily-report.sh               # today
#   ./scripts/daily-report.sh 2026-10-09    # any earlier day still in the logs

# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

DAY="${1:-$(date +%Y-%m-%d)}"
if ! date -d "$DAY" > /dev/null 2>&1; then
    echo "Usage: $0 [YYYY-MM-DD]" >&2
    exit 1
fi

UPTIME_LOG="$LOG_DIR/uptime.log"
ALERT_LOG="$LOG_DIR/alerts.log"
PERFORMANCE_LOG="$LOG_DIR/performance.csv"
REPORT="$REPORT_DIR/network-report-$DAY.txt"

mkdir -p "$REPORT_DIR"

# Alerts are logged as "YYYY-MM-DD HH:MM:SS | ALERT | ...".
# Older entries used the default `date` format ("ALERT: Fri Oct  9 11:29:42 ..."),
# where single-digit days are space-padded, so match those with a regex too.
LEGACY_DAY_PATTERN="^ALERT: $(date -d "$DAY" '+%a %b') +$(date -d "$DAY" '+%-d') .*$(date -d "$DAY" '+%Y')"

todays_alerts() {
    [[ -f "$ALERT_LOG" ]] || return 0
    grep -E "^$DAY .*\| ALERT \||$LEGACY_DAY_PATTERN" "$ALERT_LOG"
}

{
    echo "===================================="
    echo "DAILY NETWORK HEALTH REPORT"
    echo "Date: $DAY"
    echo "Generated: $(timestamp)"
    echo "===================================="
    echo " "
    echo "INTERNET AVAILABILITY SUMMARY"
    echo "------------------------------------"
    if [[ -f "$UPTIME_LOG" ]]; then
        awk -F, -v day="$DAY" '
        index($1, day) == 1 {
            total++
            if ($2 == "ONLINE") online++
        }
        END {
            printf "Total Checks: %d\n", total
            printf "Successful Checks: %d\n", online
            printf "Failed Checks: %d\n", total - online
            if (total > 0)
                printf "Internet Availability: %.2f%%\n", online / total * 100
            else
                print "Internet Availability: N/A"
        }' "$UPTIME_LOG"
    else
        echo "No uptime data found ($UPTIME_LOG)"
    fi

    echo " "
    echo "NETWORK PERFORMANCE"
    echo "------------------------------------"
    if [[ -f "$PERFORMANCE_LOG" ]]; then
        awk -F, -v day="$DAY" '
        index($1, day) != 1 { next }
        $2 != "" { loss_sum += $2; loss_n++ }
        $3 != "" {
            lat_sum += $3; lat_n++
            if (lat_n == 1 || $3 + 0 > max + 0) max = $3
        }
        END {
            if (lat_n > 0) {
                printf "Average Latency: %.2f ms\n", lat_sum / lat_n
                printf "Maximum Latency: %.2f ms\n", max
            } else
                print "Average Latency: No data"
            if (loss_n > 0)
                printf "Average Packet Loss: %.2f%%\n", loss_sum / loss_n
        }' "$PERFORMANCE_LOG"
    else
        echo "No performance data found ($PERFORMANCE_LOG)"
    fi

    echo " "
    echo "NETWORK ALERT SUMMARY"
    echo "------------------------------------"
    ALERTS=$(todays_alerts)
    if [[ -z "$ALERTS" ]]; then
        echo "Alerts Today: 0"
    else
        echo "Alerts Today: $(echo "$ALERTS" | wc -l)"
        echo " "
        echo "Alerts by Type:"
        # Strip the timestamp and any trailing detail ("- 25%", "(1.1.1.1)")
        echo "$ALERTS" \
            | sed -E 's/^.*\| ALERT \| //; s/^ALERT: [^-]* - //; s/ (- |\().*$//' \
            | sort | uniq -c | sort -rn | sed 's/^ */  /'
    fi
} > "$REPORT"

cat "$REPORT"
echo " "
echo "Report saved to $REPORT"
