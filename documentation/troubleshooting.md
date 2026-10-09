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
