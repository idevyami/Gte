#!/usr/bin/env python3
"""ENTITY_000 — rim BOOST pass #4 (WB-21, THE CENSER'S EDGE).

The WB-20 honest motion audit left readability 6-7/10 with NOT RESOLVED
notes; the WB-21 re-audit (fresh clips, anti-confabulation prompts)
measured the truth at full resolution: the congregation value-collapses
against the chapel — facing 2/10, stride shape 1/10, silhouette
separation 3/10. The robes sit at median luminance 42 against the
carpet band's 67, and the believers' baked edge (0.44 after three
bakes) reads at ~106 max where the vessel's (0.58) reads at ~150 —
the edge is what carries the read (the vessel proves it: identical
body luminance, 9/10 read, on the strength of rim + lift alone).

This pass lands the fourth bake for the congregation only — the
censer-gold edge brought to the vessel's own strength and beyond
(they are the pressing threat; their edges may burn louder than the
anchor's, warm gold against his bone).

Same compound-delta math as WB-7/17: edge pixels already carry m1,
so m2 = (M - m1) / (1 - m1) lands exactly on M.

Targets M (from the current baked state):
  believers 0.44 -> 0.70
"""
import os
import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = "/home/z/entity000/art/characters"

# set -> (rim rgb, current strength m1, NEW target M)
TINTS = {
    "believers": ((219, 189, 133), 0.44, 0.70),
}


def bake(path, rgb, strength):
    arr = np.array(Image.open(path).convert("RGBA")).astype(np.float64)
    a = arr[..., 3] > 128
    if not a.any():
        return False
    edge = a & ~ndimage.binary_erosion(a, iterations=2)
    m = edge * (arr[..., 3] / 255.0) * strength
    for i, v in enumerate(rgb):
        arr[..., i] = arr[..., i] * (1.0 - m) + v * m
    Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGBA").save(path)
    return True


def main():
    for set_name, (rgb, m1, target) in TINTS.items():
        d = os.path.join(ROOT, set_name)
        if not os.path.isdir(d):
            continue
        delta = (target - m1) / (1.0 - m1)
        n = 0
        for fn in sorted(os.listdir(d)):
            if fn.endswith(".png"):
                if bake(os.path.join(d, fn), rgb, delta):
                    n += 1
        print("%-14s rim %.2f -> %.2f (delta %.3f) on %d frames" % (set_name, m1, target, delta, n))


if __name__ == "__main__":
    main()
