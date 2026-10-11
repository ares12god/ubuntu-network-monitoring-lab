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
- Automated daily network health reports with availability statistics
- Network fault diagnosis for gateway, internet, and DNS failures
- Linux time synchronization troubleshooting using Chrony and NTP

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

## Historical Network Performance Monitoring

The Ubuntu Network Monitoring Lab automatically collects network performance measurements every five minutes using Bash and cron.

### Performance Metrics
- Average network latency (ms)
- Maximum network latency (ms)
- Average packet loss (%)
- Timestamped historical measurements

### Scripts
- `scripts/network-check.sh` - Collects network measurements and records them in a CSV file.
- `scripts/performance-report.sh` - Analyzes historical data and calculates network performance statistics.

### Data Collection
Performance measurements are stored locally in `logs/performance.csv`.

Each record contains a timestamp, packet loss percentage, and average latency.

### Running the Performance Report

```bash
./scripts/performance-report.sh
```

This project demonstrates practical experience with Linux,
Bash scripting, cron automation, network troubleshooting,
CSV logging, and performance analysis.

## Python Network Monitoring Dashboard

This project includes a Python-based dashboard that visualizes historical network performance data collected by the Ubuntu monitoring system.

### Features

- Automated data collection every five minutes using Bash and cron
- Historical latency and packet-loss tracking
- Python data processing using CSV and datetime
- Network performance visualization using Matplotlib
- PNG graph generation for troubleshooting and reporting

### Network Latency Graph

![Network Latency Over Time](dashboard/network-latency.png)

### Network Packet Loss Graph

![Network Packet Loss Over Time](dashboard/network-packet-loss.png)

### Generate the Dashboard

Install Matplotlib in a Python virtual environment, then run:

```bash
.venv/bin/python dashboard/network-dashboard.py
```
The script reads `logs/performance.csv` and generates both graphs in the `dashboard/` directory.

**Note:** Historical performance logs are stored locally and are not uploaded to GitHub.

### Skills Demonstrated

Linux Administration | Python | Bash Scripting | Network Monitoring | Cron Automation | Data Visualization | Network Troubleshooting
