# Ubuntu Firewall and SSH Security

## Overview

Configured and verified the Ubuntu UFW firewall to improve security while maintaining remote SSH access from a macOS host.

## Environment

- Operating System: Ubuntu Linux
- Virtualization: UTM on macOS
- Ubuntu IP Address: 192.168.64.2
- Default Gateway: 192.168.64.1
- Remote Access: OpenSSH (TCP port 22)

## Firewall Configuration

Checked the initial firewall status:

   sudo ufw status verbose

Allowed incoming SSH connections:

   sudo ufw allow 22/tcp

Verified the SSH rule:

   sudo ufw show added

Enabled the firewall:

   sudo ufw enable

Verified the active configuration:

   sudo ufw status verbose

## Verified Firewall Settings

- Firewall: Active
- Incoming Traffic: Denied by default
- Outgoing Traffic: Allowed by default
- SSH TCP Port 22: Allowed
- IPv4 and IPv6 SSH Rules: Enabled
- Firewall Logging: Enabled (low)

## SSH Connectivity Testing

Verified that the SSH socket was running:

   systemctl status ssh.socket

Connected from the macOS host using:

   ssh c-money12@192.168.64.2

Result: SSH connection successful after enabling the firewall.

## Troubleshooting Lessons

- Verify SSH rules before enabling a firewall.
- Test remote access after firewall changes.
- Use ss to identify listening network ports.
- Use systemctl to inspect Linux services.
- Use UFW to control incoming network traffic.

## Skills Demonstrated

Linux Security | UFW | SSH | TCP/IP | Firewall Management | Remote Administration | Network Troubleshooting
