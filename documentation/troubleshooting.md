# Network Monitoring Lab - Troubleshooting

## Issue 1: Alert Log Not Being Created

**Problem:** The monitoring script did not create the alerts.log file.

**Cause:** The ALERT_LOG variable contained an incorrect file path.

**Resolution:** Corrected the path to use $HOME/home-lab/logs/alerts.log.

**Lesson Learned:** Linux file paths and environment variables must be accurate.

## Issue 2: Incorrect Network Status

**Problem:** The script reported packet loss even when ping showed 0% packet loss.

**Cause:** The script was incorrectly extracting or comparing ping results.

**Resolution:** Corrected the Bash parsing and conditional logic.

**Lesson Learned:** Always verify script output against actual network test results.

## Issue 3: GitHub Authentication Failure

**Problem:** Git repeatedly rejected HTTPS authentication.

**Resolution:** Installed GitHub CLI and authenticated successfully.

**Lesson Learned:** GitHub CLI simplifies secure Git authentication.

## Issue 4: Simulated Internet Outage Test

**Problem:** Needed to verify that the monitoring script could detect and report a complete Internet outage.

**Cause:** A simulated outage was created by pinging the reserved test IP address 192.0.2.1.

**Resolution:** The script detected 100% packet loss, classified the connection as OFFLINE, generated an alert, and recorded the diagnosis. Separate test logs were used. (This is now built into the main script: `INTERNET_TARGET=192.0.2.1 LOG_DIR=/tmp/lab-test ./scripts/network-check.sh`.)

**Lesson Learned:** Testing failure scenarios helps verify monitoring accuracy and ensures alerts work correctly.

## Issue 5: Ubuntu System Clock Synchronization Failure

**Problem:** Ubuntu displayed an incorrect date and time, causing daily network health reports to contain inaccurate timestamps.

**Cause:** Chrony was running but had not established synchronization with a valid NTP time source.

**Resolution:** Investigated using timedatectl, systemctl status chrony, chronyc sources -v, and chronyc tracking. Applied sudo chronyc makestep to correct the clock and restarted Chrony to establish synchronization.

**Lesson Learned:** Accurate system time is essential for reliable monitoring, incident investigation, scheduled tasks, and log correlation.

**Recurrence (October 21, 2026):** The clock fell behind again, this time by 49 minutes. Reports were stamped 14:06 when the real time was about 14:58.

**Root Cause:** The VM runs in UTM on a MacBook. When the Mac sleeps, the VM is paused, and when it resumes, its system clock picks up from where it stopped. `timedatectl` confirmed this: the hardware clock (RTC) was correct while the system clock was 49 minutes slow. Chrony was running, but its default setting, `makestep 1 3`, only allows large jumps during the first three clock updates after boot. After that, Chrony corrects gradually, which would take days to close a 49-minute gap.

**Permanent Fix:** Changed the setting in `/etc/chrony/chrony.conf` to `makestep 1 -1`, which allows Chrony to step the clock whenever it is off by more than one second, then restarted the service:

    sudo sed -i 's/^makestep 1 3$/makestep 1 -1/' /etc/chrony/chrony.conf
    sudo systemctl restart chrony

Verified with `timedatectl`: local time matched the host and "System clock synchronized" returned `yes`.

**Lesson Learned:** A fix that works once may not address the root cause. Virtual machines that are paused and resumed need time sync configured to correct large offsets at any time, not only at boot.

## Issue 6: Daily Report Showed Zero Alerts on a Day With an Incident

**Problem:** The October 9 daily report showed "Alerts Today: 0", but the incident investigation for the same day counted 15 alerts.

**Cause:** Alerts were timestamped with the default `date` format, which pads single-digit days with a space (`Fri Oct  9`). The report searched for `Fri Oct 9 ` with a single space, so it never matched on the 1st through the 9th of any month.

**Resolution:** All logs now use a sortable, locale-independent timestamp (`2026-10-09 11:29:42`). The daily report matches both the new format and the old one, and accepts a date argument, so past reports can be regenerated: `./scripts/daily-report.sh 2026-10-09`.

**Lesson Learned:** Use ISO 8601-style timestamps in logs, and cross-check reports against the raw data.

## Issue 7: Complete Outages Were Recorded as Packet Loss

**Problem:** When the network had no route at all, the check logged "PACKET LOSS DETECTED" and the uptime log recorded the Internet as ONLINE.

**Cause:** With no route, `ping` fails immediately with "Network is unreachable" and never prints its statistics line. The packet-loss value was left empty, which did not equal "100", so the outage fell through to the packet-loss branch.

**Resolution:** An empty packet-loss result is now treated as 100% loss (a full outage). Tested by simulating the no-route case, a gateway that drops ping, packet loss, high latency, and recovery.

**Lesson Learned:** Test monitoring against every failure mode, including the ones where the tool itself errors out instead of reporting a result.
