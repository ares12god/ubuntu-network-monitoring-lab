#!/bin/bash

PERFORMANCE_LOG="$HOME/home-lab/logs/performance.csv"

# Calculate average latency
awk -F, '$3 != " " {sum += $3; count++} END {
    if (count > 0)
        printf "Average Latency: %.2f ms\n", sum/count
    else
        print "Average Latency: No data"
}' "$PERFORMANCE_LOG"

# Calculate maximum latency
awk -F, '$3 != " " {
    if (!found || $3 > max)
        max = $3
    found = 1
} END {
    if (found)
        printf "Maximum Latency: %.2f ms\n", max
    else
        print "Maximum Latency: No data"
}' "$PERFORMANCE_LOG"

# Calculate average packet loss
awk -F, '$2 != " " {
    sum += $2
    count++
} END {
    if (count > 0)
        printf "Average Packet Loss: %.2f%%\n", sum/count
    else
        print "Average Packet Loss: No data"
}' "$PERFORMANCE_LOG"
