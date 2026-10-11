import csv
from datetime import datetime
from pathlib import Path
import matplotlib.pyplot as plt

# Locate the home lab performance date
BASE_DIR =  Path.home() / "home-lab"
CSV_FILE = BASE_DIR / "logs" / "performance.csv"

# Store network measurements
timestamps = [ ]
latencies = [ ]
packet_losses = [ ]

# Read historical network performance data
with open(CSV_FILE, newline="") as file:
    reader = csv.reader(file)

    for row in reader:
        if len(row) != 3:
            continue

        timestamp, loss, latency = row

        if not latency:
            continue

        timestamps.append(
             datetime.strptime(timestamp, "%Y-%m-%d %H:%M:%S")
        )
        packet_losses.append(float(loss))
        latencies.append(float(latency))

# Create a network latency graph
if timestamps:
    plt.figure(figsize=(12,6))
    plt.plot(timestamps, latencies, marker="o")

    plt.title("Network Latency Over Time")
    plt.xlabel("Date and Time")
    plt.ylabel("Average Latency (ms)")

    plt.grid(True)
    plt.xticks(rotation=45)
    plt.tight_layout()

# Save the graph
OUTPUT_FILE = BASE_DIR / "dashboard" / "network-latency.png"
plt.savefig(OUTPUT_FILE)
plt.close()

print(f"Dashboard saved to: {OUTPUT_FILE}")

# Create a network packet loss graph
if timestamps:
    plt.figure(figsize=(12, 6))
    plt.plot(timestamps, packet_losses, marker="o")

    plt.title("Network Packet Loss Over Time")
    plt.xlabel("Date and Time")
    plt.ylabel("Packet Loss (%)")

    plt.grid(True)
    plt.xticks(rotation=45)
    plt.tight_layout()

    OUTPUT_FILE = BASE_DIR / "dashboard" / "network-packet-loss.png"
    plt.savefig(OUTPUT_FILE)
    plt.close()
