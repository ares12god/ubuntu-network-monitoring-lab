#
# Ubuntu Network Monitoring & Troubleshooting Lab

## Project Overview
Built an automated network monitoring system using Ubuntu Linux and Bash scripting to monitor connectivity, latency, packet loss, and DNS resolution.

## Technologies Used
- Ubuntu Linux
- Bash scripting
- Cron job scheduling
- Ping and Linux networking utilities
- DNS resolution with getent
- Linux log files

## Features
- Automated network checks every 5 minutes
- Internet connectivity monitoring
- Packet loss detection
- Average network latency measurement
- High latency alerts above 100 ms
- DNS resolution monitoring
- Timestamped monitoring and alert logs
- Automatic default gateway detection and connectivity monitoring
- Automatic Internet availability tracking every five minutes
- Uptime reporting with total checks, successful checks, failed checks, and availability percentage

## Project Structure
- scripts/network-check.sh - Main monitoring script
- logs/network-check.log - Network monitoring history
- logs/alerts.log - Recorded network alerts
- documentation/network-baseline.txt - Initial network baseline

## Skills Demonstrated
- Linux command-line administration
- Network troubleshooting
- TCP/IP connectivitiy testing
- Bash scripting
- Task automation using cron
- Network performance monitoring
- Troubleshooting and debugging

## Future Improvements
- Monitoring dashboard
- Email notifications
- Historical performance reporting
- Additional network monitoring targets

## Troubleshooting Experience

During developement, I diagnosed and resolved several technical issues:

- Corrected Bash script logic that incorrectly reported packet loss.
- Fixed Linux file paths that prevented alert logs from being created.
- Troubleshot GitHub authentication failures using GitHub CLI.

These challenges strengthened my Linux troubleshooting, scripting, and problem-solving skills.

For detailed troubleshooting steps, see the [Troubleshooting Documentation](documentation/troubleshooting.md)
