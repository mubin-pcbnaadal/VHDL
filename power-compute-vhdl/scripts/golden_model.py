#!/usr/bin/env python3
"""
Bit-exact reference model of power_compute driven by the testbenches.

It regenerates the same integer samples as the VHDL testbench
(x_k = integer(A * sin(2*pi*f*k*Ts)), VHDL rounding = half away from zero),
then computes  P = floor( sum(x_k^2) / N )  for every computation window.
Window w uses samples w*N+1 .. w*N+N (one clock of FSM latency: IDLE -> FIRST).

Usage:  python3 scripts/golden_model.py [fast|a1]
"""
import math
import sys

CONFIGS = {
    # name : (m, Ts in seconds as seen by the testbench, sine frequency)
    "fast": (8, 100e-9, 781250.0),
    "a1":   (10, 976562e-9, 50.0),   # Tclk/1 ns truncated, as in the testbench
}


def vhdl_round(x: float) -> int:
    return int(math.floor(x + 0.5)) if x >= 0 else -int(math.floor(-x + 0.5))


def main() -> None:
    name = sys.argv[1] if len(sys.argv) > 1 else "fast"
    m, ts, freq = CONFIGS[name]
    n = 2 ** m
    amp = 32767.0
    print(f"testbench '{name}' : N = {n}")
    print(f"{'window':>6} {'amplitude':>12} {'P (model)':>12} {'A^2/2':>12} {'ratio':>7}")
    prev = None
    for w in range(8):
        a = amp / 2 ** w
        s = sum(vhdl_round(a * math.sin(2 * math.pi * freq * k * ts)) ** 2
                for k in range(w * n + 1, w * n + n + 1))
        p = s // n
        ratio = f"{prev / p:7.3f}" if prev else "      -"
        print(f"{w:>6} {a:>12.4f} {p:>12d} {a * a / 2:>12.0f} {ratio}")
        prev = p
    print("(the testbenches skip window 4 : C = 0, standby)")


if __name__ == "__main__":
    main()
