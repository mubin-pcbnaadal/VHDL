#!/usr/bin/env python3
"""
Draw ModelSim-style waveform pictures from a GHDL VCD dump of the fast testbench.

Usage:  python3 scripts/plot_waves.py build/tb_fast.vcd docs/img
(produced by `make waves`)
"""
import os
import sys
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon

VCD, OUT = sys.argv[1], sys.argv[2]
os.makedirs(OUT, exist_ok=True)

# hierarchical VCD name -> short name used below
WANTED = {"test_power_compute.reset": "reset", "test_power_compute.c": "C",
          "test_power_compute.clock": "clock", "test_power_compute.x": "X",
          "test_power_compute.p": "P", "test_power_compute.amp": "amp",
          "test_power_compute.c1.clr_cnt": "clr_cnt", "test_power_compute.c1.inc_cnt": "inc_cnt",
          "test_power_compute.c1.init": "init", "test_power_compute.c1.ld_acc": "ld_acc",
          "test_power_compute.c1.ld_p": "ld_p", "test_power_compute.c1.end_cnt": "end_cnt",
          "test_power_compute.c1.cnt": "cnt", "test_power_compute.c1.acc": "acc"}
signed = {"X"}
ids, scope = {}, []
tr = {v: [] for v in WANTED.values()}
t, started, tscale = 0, False, 1e-6   # default fs -> ns
lines = open(VCD).read().split("\n")
for k, line in enumerate(lines):
    line = line.strip()
    if not started:
        if line.startswith("$scope"): scope.append(line.split()[2])
        elif line.startswith("$upscope"): scope.pop()
        elif line.startswith("$var"):
            f = line.split()
            full = ".".join(scope + [f[4].split("[")[0]])
            if full in WANTED: ids[f[3]] = WANTED[full]
        elif line.startswith("$timescale"):
            ts = (line[len("$timescale"):] + " " + lines[k + 1]).replace("$end", "").split()
            num = int("".join(c for c in ts[0] if c.isdigit()))
            unit = ts[0].lstrip("0123456789") or ts[1]
            tscale = num * {"fs": 1e-6, "ps": 1e-3, "ns": 1.0, "us": 1e3}[unit]
        elif line.startswith("$enddefinitions"): started = True
        continue
    if not line: continue
    if line[0] == "#": t = int(line[1:]) * tscale; continue
    if line[0] in "br":
        val, i = line[1:].split()
        if i not in ids: continue
        n = ids[i]
        if line[0] == "r": v = float(val)
        elif any(c not in "01" for c in val): v = 0
        else:
            v = int(val, 2)
            if n in signed and len(val) == 16 and val[0] == "1": v -= 1 << 16
    else:
        i = line[1:]
        if i not in ids: continue
        n = ids[i]; v = 1 if line[0] == "1" else 0
    tr[n].append((t, v))

TEND = t
def val_at(n, tt):
    v = 0
    for (a, b) in tr[n]:
        if a <= tt: v = b
        else: break
    return v

def steps(n, t0, t1):
    xs, ys = [], []
    v = val_at(n, t0); xs.append(t0); ys.append(v)
    for (a, b) in tr[n]:
        if t0 < a < t1:
            xs += [a, a]; ys += [v, b]; v = b
    xs.append(t1); ys.append(v)
    return xs, ys

def state_trace(t0, t1):
    names = ["init", "ld_acc", "ld_p", "clr_cnt"]
    times = sorted({a for n in names for (a, _) in tr[n] if t0 < a < t1} | {t0})
    out = []
    for tt in times:
        i, la, lp = val_at("init", tt), val_at("ld_acc", tt), val_at("ld_p", tt)
        s = "FIRST" if i else "LAST" if lp else "ACCU" if la else "IDLE"
        if not out or out[-1][1] != s: out.append((tt, s))
    return out

def bus_segments(n, t0, t1):
    seg = [(t0, val_at(n, t0))]
    for (a, b) in tr[n]:
        if t0 < a < t1 and b != seg[-1][1]: seg.append((a, b))
    return seg

BG, GRID, GREEN, CY, YEL, ORG, WHITE, MAG, RED = "#000000", "#3a3a3a", "#33ff33", "#33e0ff", "#ffee33", "#ff9a2e", "#e8e8e8", "#ff66ff", "#ff4444"

def draw(rows, t0, t1, unit, title, fname, grid=None):
    heights = [r[2] for r in rows]
    fig = plt.figure(figsize=(15, sum(heights) * 0.55 + 1.3), facecolor="#d4d0c8")
    fig.suptitle(title, fontsize=13, fontweight="bold", x=0.02, ha="left")
    tot = sum(heights)
    gs = fig.add_gridspec(len(rows), 1, height_ratios=heights, hspace=0.0,
                          left=0.14, right=0.985, top=0.93, bottom=0.07)
    sc = 1e3 if unit == "us" else 1.0
    for k, (label, kind, h, n, color) in enumerate(rows):
        ax = fig.add_subplot(gs[k]); ax.set_facecolor(BG)
        ax.set_xlim(t0 / sc, t1 / sc)
        for sp in ax.spines.values(): sp.set_color("#555")
        ax.tick_params(left=False, labelleft=False, bottom=(k == len(rows) - 1), colors="#222")
        if grid:
            g = t0
            while g <= t1:
                ax.axvline(g / sc, color=GRID, lw=0.8, zorder=0); g += grid
        fig.text(0.135, (ax.get_position().y0 + ax.get_position().y1) / 2, label,
                 ha="right", va="center", fontsize=10, family="monospace", fontweight="bold")
        if kind == "bit":
            xs, ys = steps(n, t0, t1)
            ax.plot([x / sc for x in xs], ys, color=color, lw=1.2, drawstyle="default")
            ax.set_ylim(-0.4, 1.4)
        elif kind == "analog":
            xs, ys = steps(n, t0, t1)
            ax.plot([x / sc for x in xs], ys, color=color, lw=1.0)
            lo, hi = (-34000, 34000) if n == "X" else (-2e7, 5.7e8)
            ax.set_ylim(lo, hi)
            if n == "P":
                for (a, b) in bus_segments("P", t0, t1)[1:]:
                    if b: ax.text(a / sc + (t1 - t0) / sc * 0.004, b + 1.5e7, f"{b:,}".replace(",", " "),
                                  color=color, fontsize=8.5, va="bottom")
        elif kind in ("bus", "state"):
            seg = state_trace(t0, t1) if kind == "state" else bus_segments(n, t0, t1)
            seg = seg + [(t1, None)]
            d = (t1 - t0) * 0.003
            for (a, v), (b, _) in zip(seg[:-1], seg[1:]):
                col = color
                if kind == "state":
                    col = {"IDLE": "#888888", "FIRST": "#33ff33", "ACCU": MAG, "LAST": RED}[v]
                poly = Polygon([(a / sc, .5), ((a + d) / sc, .85), ((b - d) / sc, .85), (b / sc, .5),
                                ((b - d) / sc, .15), ((a + d) / sc, .15)], closed=True,
                               fill=(kind == "state"), facecolor=col + "40" if kind == "state" else None,
                               edgecolor=col, lw=1.1)
                ax.add_patch(poly)
                txt = v if kind == "state" else (f"{v:,}".replace(",", " ") if n != "amp" else f"{v:.6g}")
                if (b - a) / (t1 - t0) > 0.025:
                    ax.text((a + b) / 2 / sc, .5, txt, color=WHITE, ha="center", va="center", fontsize=8.5,
                            clip_on=True)
            ax.set_ylim(0, 1)
    ax.set_xlabel(f"time ({unit})", fontsize=10)
    fig.savefig(fname, dpi=110, facecolor=fig.get_facecolor())
    plt.close(fig)

full = [("reset", "bit", 1, "reset", RED), ("C", "bit", 1, "C", ORG),
        ("amp", "bus", 1, "amp", WHITE), ("X (input)", "analog", 4, "X", CY),
        ("state", "state", 1, None, MAG), ("P (curve)", "analog", 4, "P", YEL),
        ("P value", "bus", 1, "P", YEL)]
draw(full, 0, TEND, "us",
     "1) Full run - X amplitude halves every 25.6 us, P divided by 4 after each computation "
     "(C=0 -> standby during 102-128 us, P held)", OUT + "/wave_full.png", grid=25600)

zoom = [("clock", "bit", 1, "clock", GREEN), ("C", "bit", 1, "C", ORG),
        ("X", "bus", 1, "X", CY), ("state", "state", 1, None, MAG),
        ("cnt", "bus", 1, "cnt", WHITE), ("end_cnt", "bit", 1, "end_cnt", RED),
        ("init", "bit", 1, "init", GREEN), ("ld_acc", "bit", 1, "ld_acc", GREEN),
        ("ld_p", "bit", 1, "ld_p", GREEN), ("clr_cnt", "bit", 1, "clr_cnt", GREEN),
        ("P value", "bus", 1, "P", YEL)]
draw(zoom, 25150, 26050, "us",
     "2) Zoom on the end of computation 0 (25.15-26.05 us) - ACCU -> LAST -> FIRST, P loaded at the end of LAST",
     OUT + "/wave_zoom.png", grid=100)

draw(zoom, 102150, 102950, "us",
     "3) Zoom where C=0 - last computation finishes (LAST), then IDLE: standby, P stays constant",
     OUT + "/wave_standby.png", grid=100)
print("ok")
