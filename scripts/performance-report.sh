#!/bin/bash
# Network Performance Report
# Calculates latency and packet-loss statistics from the history that
# network-check.sh records in logs/performance.csv.
#
# Usage:
#   ./scripts/performance-report.sh               # all recorded history
#   ./scripts/performance-report.sh 2026-10-14    # a single day

# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

PERFORMANCE_LOG="$LOG_DIR/performance.csv"
DAY="${1:-}"

if [[ ! -s "$PERFORMANCE_LOG" ]]; then
    echo "No performance data yet ($PERFORMANCE_LOG). Run network-check.sh first."
    exit 0
fi

echo "===== NETWORK PERFORMANCE REPORT ====="
echo "Period: ${DAY:-all recorded history}"

# Rows look like: 2026-10-14 15:45:05,0,12.4
# Latency is empty when every ping was lost, so those rows count toward
# packet loss but are skipped for latency (counting them as 0 ms would
# pull the average down during outages).
awk -F, -v day="$DAY" -v threshold="$LATENCY_THRESHOLD_MS" '
day != "" && index($1, day) != 1 { next }
{
    samples++
    if (first == "" || $1 < first) first = $1
    if ($1 > last) last = $1
}
$2 != "" {
    loss_sum += $2; loss_n++
    if ($2 + 0 > 0) lossy++
    if ($2 + 0 == 100) outages++
}
$3 != "" {
    lat_sum += $3; lat_n++
    if (lat_n == 1 || $3 + 0 < min + 0) min = $3
    if (lat_n == 1 || $3 + 0 > max + 0) max = $3
    if ($3 + 0 > threshold + 0) slow++
}
END {
    if (samples == 0) { print "No measurements for this period."; exit }
    printf "Measurements: %d (%s to %s)\n", samples, first, last
    if (lat_n > 0) {
        printf "Average Latency: %.2f ms\n", lat_sum / lat_n
        printf "Minimum Latency: %.2f ms\n", min
        printf "Maximum Latency: %.2f ms\n", max
        printf "Checks Above %d ms: %d\n", threshold, slow
    } else
        print "Latency: No successful measurements"
    if (loss_n > 0) {
        printf "Average Packet Loss: %.2f%%\n", loss_sum / loss_n
        printf "Checks With Packet Loss: %d\n", lossy
        printf "Checks With 100%% Loss (outage): %d\n", outages
    }
}' "$PERFORMANCE_LOG"
