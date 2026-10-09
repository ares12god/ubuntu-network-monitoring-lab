# Network Monitoring Lab - Troubleshooting

## Issue 1: Alert Log Not Being Created

**Problem:** The monitoring script did not create the alerts.log file.

**Cause:** The ALERT_LOG variable contained an incorrect file path.

**Resolution:** Corrected the path to use $HOME/home-lab/logs/alerts.log.

**Lessom Learned:** Linux file paths and environment variables must be accurate.

## Issue 2: Incorrect Network Status

**Problem:** The script reported packet loss even when ping showed 0% packet loss.

**Cause:** The script was incorrectly extracting or comparing ping results.

**Resolution:** Corrected the Bash parsing and conditional logic.

**Lesson Learned:** Always verify script output against actual network test results.

## Issue 3: Github Authentication Failure

**Problem:** Git repeatedly rejected HTTPS authentication.

**Resolution:** Installed GitHub CLI and authenticated successfully.

**Lesson Learned:** GitHub CLI simplifies secure Git authentication.

## Issue 4: Simulated Internet Outage Test

**Problem:** Needed to verify that the monitoring script could detect and report a complete Internet outage.

**Cause:** A simulated outage was created by pinging the reserved test IP address 192.0.2.1.

**Resolution:** The script detected 100% packet loss, classified the connection as OFFLINE, generated an alert, and recorded the diagnosis. Seperate tes logs were used.

**Lesson Learned:** Testing failure scenarios helps verify monitoring accuracy and ensures alerts work correctly.
