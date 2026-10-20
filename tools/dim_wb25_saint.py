#!/usr/bin/env python3
"""WB-25 — THE SAINT SITS DEEPER: the chapel backdrop's painted saint dimmed.

THE FINDING (proof_wb25, five VLM audits): every camera slice of the chantry
traces "a tall pale statue of a robed woman with open hands" — the room's
own namesake, painted at the backdrop's center (x~590-680 of 1344). She
reads CORRECTLY as a statue, but she is tiled to ~511px on a near-world
plane and her body columns (raw mean 105-124) outshine everything in the
room's upper air (believers' lit hoods read 75; the jamb tops 59-64) —
"the primary light-colored focal point in the center" is background
architecture, and the grammar law (WB-23) says the room's brightest
presences belong to its bodies and its relic.

THE FIX: a feathered elliptical multiply over her statue+pedestal zone —
she keeps her silhouette, her pose, her altar; she simply sits a step
deeper in the chapel's air. The candelabras flanking her (x~452-528 and
x~752-832) are OUTSIDE the mask and keep their voice (far furniture).

Deterministic; run from the repo root:
    python3 tools/dim_wb25_saint.py [--measure-only]
"""
from PIL import Image

SRC = "art/backdrops/backdrop_chapel.png"

# the mask: an ellipse over the statue + pedestal, feathered so the wall
# behind her dims smoothly back to full brightness
CX, CY = 635.0, 505.0       # mask center (painting pixels)
RX, RY = 88.0, 252.0        # radii: covers x~547-723, y~253-757
FEATHER = 0.34              # fraction of the radius that ramps 0->1
MULT = 0.56                 # the dim multiplier at the mask's core
FOG = (51, 41, 31)          # the room's air (0.2, 0.16, 0.12 in 0-255)
FOG_K = 0.22                # how far the dimmed saint leans into the air

def smoothstep(t: float) -> float:
    t = max(0.0, min(1.0, t))
    return t * t * (3.0 - 2.0 * t)

def main() -> None:
    import sys
    measure_only = "--measure-only" in sys.argv
    img = Image.open(SRC).convert("RGBA")
    px = img.load()
    W, H = img.size

    def zone_stats(label: str) -> None:
        best = 0
        s = 0
        n = 0
        for x in range(590, 681):
            for y in range(300, 741):
                r, g, b, a = px[x, y]
                lum = int(0.299 * r + 0.587 * g + 0.114 * b)
                if a > 0:
                    best = max(best, lum)
                    s += lum
                    n += 1
        print(f"{label}: saint body zone peak={best} mean={s / max(n, 1):.0f}")

    zone_stats("before")
    if measure_only:
        return

    for x in range(int(CX - RX - 4), int(CX + RX + 4)):
        for y in range(int(CY - RY - 4), int(CY + RY + 4)):
            if not (0 <= x < W and 0 <= y < H):
                continue
            # normalized elliptical distance, feathered
            dx = (x - CX) / RX
            dy = (y - CY) / RY
            d = (dx * dx + dy * dy) ** 0.5
            k = smoothstep((d - (1.0 - FEATHER)) / FEATHER)   # 0 core -> 1 edge
            if k >= 1.0:
                continue
            m = 1.0 - (1.0 - MULT) * (1.0 - k)
            r, g, b, a = px[x, y]
            nr = r * m + FOG[0] * FOG_K * (1.0 - k)
            ng = g * m + FOG[1] * FOG_K * (1.0 - k)
            nb = b * m + FOG[2] * FOG_K * (1.0 - k)
            px[x, y] = (int(max(0, min(255, nr))),
                        int(max(0, min(255, ng))),
                        int(max(0, min(255, nb))), a)
    img.save(SRC)
    zone_stats("after ")

if __name__ == "__main__":
    main()
