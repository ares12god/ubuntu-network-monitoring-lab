#!/bin/bash

# Internet availability report
UPTIME_LOG="$HOME/home-lab/logs/uptime.log"

awk -F, '
{
     total++
     if ($2 == "ONLINE") online++
}
END {
     if (total > 0) {
         printf "Total checks: %d\n", total
         printf "Successful Checks: %d\n", online
         printf "Failed Checks: %d\n", total-online
         printf "Internet Availability: %.2f%%\n", online/total*100
    } else {
         print "No uptime data available"
    }
}' "$UPTIME_LOG"
