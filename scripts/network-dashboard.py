import csv
from pathlib import Path
import matplotlib.pyplot as plt

DATA_FILE = Path.home() / "home-lab/logs/performance.csv"

timestamps = []
packet_loss = []
latency = []

with open(DATA_FILE, "r") as file:
    reader = csv.reader(file)
    for row in reader:
        if len(row) < 3 or not row[2].strip():
            continue
        timestamps.append(row[0])
        packet_loss.append(float(row[1]))
        latency.append(float(row[2]))

plt.figure(figsize=(12, 8))
plt.subplot(2, 1, 1)
plt.title("Network Latency Monitoring")
plt.plot(timestamps, latency, label="Latency (ms)")
plt.ylabel("Latency (ms)")
plt.legend()
plt.xticks(range(0, len(timestamps), max(1, len(timestamps)//10)), rotation=45)
plt.subplot(2, 1, 2)
plt.plot(timestamps, packet_loss, label="Packet Loss (%)")
plt.ylabel("Packet Loss (%)")
plt.title("Packet Loss Monitoring")
plt.xlabel("Time (Network Measurements)")
plt.legend()
plt.xticks(range(0, len(timestamps), max(1, len(timestamps)//10)), rotation=45)
plt.tight_layout(h_pad=3.0)
plt.savefig(Path.home() / "home-lab/network-dashboard.png")
