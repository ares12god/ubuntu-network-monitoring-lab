"""Network performance dashboard.

Reads the latency and packet-loss history that network-check.sh records in
logs/performance.csv and renders a two-panel PNG:

  * latency over time, with the high-latency alert threshold marked
  * packet loss over time, with full outages (100% loss) shaded

Usage:
    python3 scripts/network-dashboard.py              # all history
    python3 scripts/network-dashboard.py --days 7     # last 7 days only

Honors the same LAB_DIR / LOG_DIR / REPORT_DIR / LATENCY_THRESHOLD_MS
environment overrides as the Bash scripts.
"""

import argparse
import csv
import os
import sys
from datetime import datetime, timedelta
from pathlib import Path

import matplotlib

matplotlib.use("Agg")  # render to a file; works from cron with no display
import matplotlib.dates as mdates
import matplotlib.pyplot as plt

LAB_DIR = Path(os.environ.get("LAB_DIR", Path(__file__).resolve().parent.parent))
LOG_DIR = Path(os.environ.get("LOG_DIR", LAB_DIR / "logs"))
REPORT_DIR = Path(os.environ.get("REPORT_DIR", LAB_DIR / "reports" / "generated"))
DATA_FILE = LOG_DIR / "performance.csv"
OUTPUT_FILE = REPORT_DIR / "network-dashboard.png"
LATENCY_THRESHOLD_MS = float(os.environ.get("LATENCY_THRESHOLD_MS", 100))

# Checks run every 5 minutes; a longer silence means the VM was off or cron
# didn't run, so the line is broken there instead of drawn across the gap.
MAX_GAP = timedelta(minutes=15)

SERIES_COLOR = "#2a78d6"
OUTAGE_COLOR = "#d03b3b"
TEXT_COLOR = "#52514e"
GRID_COLOR = "#e4e3df"


def load_measurements(path, since=None):
    """Return a list of (timestamp, loss %, latency ms or None) rows."""
    rows = []
    with open(path, newline="") as file:
        for row in csv.reader(file):
            if len(row) < 2:
                continue
            try:
                when = datetime.strptime(row[0].strip(), "%Y-%m-%d %H:%M:%S")
                loss = float(row[1])
            except ValueError:
                continue
            if since and when < since:
                continue
            # Latency is empty when every ping was lost. Keep the row: it is
            # an outage and must show up on the packet-loss chart.
            latency = None
            if len(row) > 2 and row[2].strip():
                try:
                    latency = float(row[2])
                except ValueError:
                    pass
            rows.append((when, loss, latency))
    rows.sort(key=lambda r: r[0])
    return rows


def with_gaps(times, values):
    """Insert a break (NaN) wherever consecutive checks are too far apart."""
    out_t, out_v = [], []
    for i, (t, v) in enumerate(zip(times, values)):
        if i and t - times[i - 1] > MAX_GAP:
            out_t.append(times[i - 1] + (t - times[i - 1]) / 2)
            out_v.append(float("nan"))
        out_t.append(t)
        out_v.append(float("nan") if v is None else v)
    return out_t, out_v


def style_axis(ax, title, ylabel):
    ax.set_title(title, loc="left", fontsize=12, color="#0b0b0b", pad=10)
    ax.set_ylabel(ylabel, color=TEXT_COLOR)
    ax.grid(axis="y", color=GRID_COLOR, linewidth=0.8)
    ax.set_axisbelow(True)
    for side in ("top", "right"):
        ax.spines[side].set_visible(False)
    for side in ("left", "bottom"):
        ax.spines[side].set_color(GRID_COLOR)
    ax.tick_params(colors=TEXT_COLOR, labelsize=9)
    ax.xaxis.set_major_locator(mdates.AutoDateLocator(maxticks=10))
    ax.xaxis.set_major_formatter(mdates.DateFormatter("%b %d\n%H:%M"))


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--days", type=int, help="only plot the last N days")
    args = parser.parse_args()

    if not DATA_FILE.exists():
        sys.exit(f"No performance data at {DATA_FILE}. Run network-check.sh first.")

    since = datetime.now() - timedelta(days=args.days) if args.days else None
    rows = load_measurements(DATA_FILE, since)
    if not rows:
        sys.exit("No measurements in the selected period.")

    times = [r[0] for r in rows]
    losses = [r[1] for r in rows]
    latencies = [r[2] for r in rows]
    outages = [t for t, loss in zip(times, losses) if loss >= 100]

    fig, (ax_lat, ax_loss) = plt.subplots(2, 1, figsize=(12, 7.5), sharex=True)
    fig.patch.set_facecolor("white")

    # Latency
    lat_t, lat_v = with_gaps(times, latencies)
    ax_lat.plot(lat_t, lat_v, color=SERIES_COLOR, linewidth=1.5)
    ax_lat.axhline(LATENCY_THRESHOLD_MS, color=TEXT_COLOR, linewidth=1, linestyle="--")
    ax_lat.annotate(
        f"Alert threshold ({LATENCY_THRESHOLD_MS:g} ms)",
        xy=(1, LATENCY_THRESHOLD_MS), xycoords=("axes fraction", "data"),
        xytext=(0, 4), textcoords="offset points", ha="right", va="bottom",
        fontsize=9, color=TEXT_COLOR,
    )
    ax_lat.set_ylim(bottom=0)
    style_axis(ax_lat, "Average latency to Internet target", "Latency (ms)")

    # Packet loss
    loss_t, loss_v = with_gaps(times, losses)
    ax_loss.plot(loss_t, loss_v, color=SERIES_COLOR, linewidth=1.5)
    ax_loss.set_ylim(0, 105)
    style_axis(ax_loss, "Packet loss", "Packet loss (%)")

    # Shade full outages on both panels, labeled so it isn't color-only
    for when in outages:
        for ax in (ax_lat, ax_loss):
            ax.axvspan(when - timedelta(minutes=2.5), when + timedelta(minutes=2.5),
                       color=OUTAGE_COLOR, alpha=0.18, linewidth=0)
    if outages:
        ax_loss.text(1, 1.02, f"Shaded bands: {len(outages)} check(s) with 100% loss (outage)",
                     transform=ax_loss.transAxes, fontsize=9, color=TEXT_COLOR,
                     ha="right", va="bottom")

    first, last = times[0], times[-1]
    fig.suptitle(
        f"Network performance  ·  {first:%Y-%m-%d %H:%M} to {last:%Y-%m-%d %H:%M}"
        f"  ·  {len(rows)} checks",
        x=0.01, ha="left", fontsize=10, color=TEXT_COLOR,
    )
    fig.tight_layout(h_pad=2.5)

    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    fig.savefig(OUTPUT_FILE, dpi=120)
    print(f"Dashboard saved to {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
