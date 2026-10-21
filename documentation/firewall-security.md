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

## Finding: Unintended iperf3 Service (October 21, 2026)

**Detection:** The listening-ports step of `scripts/network-diagnostics.sh` (`ss -tuln`) showed TCP port 5201 listening on all interfaces (`*:5201`). No service on that port had been set up intentionally.

**Identification:** Matched the port to its process:

    sudo ss -tlnp | grep 5201

The output showed `iperf3` (a network bandwidth-testing tool) with a low process ID, which meant it was a system service starting at boot. Ubuntu's iperf3 package offers to run it as a background server during installation.

**Risk:** UFW's default deny-incoming policy already blocked the port, so it was not reachable from outside the VM. It was still an unneeded service exposed on every interface, which a single firewall change could have opened up.

**Remediation:** Stopped the service and disabled it from starting at boot:

    sudo systemctl disable --now iperf3

**Verification:** `sudo ss -tlnp | grep 5201` returned no output, confirming the port was closed. The VM now listens externally only on SSH (TCP 22).

**Lesson Learned:** A firewall is one layer of defense, not a reason to leave services running. Review listening ports regularly, identify the process behind each one, and disable anything that isn't needed (defense in depth and least functionality).

## Skills Demonstrated

Linux Security | UFW | SSH | TCP/IP | Firewall Management | Remote Administration | Network Troubleshooting | Attack Surface Reduction
