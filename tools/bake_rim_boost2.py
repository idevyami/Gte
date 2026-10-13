#!/usr/bin/env python3
"""ENTITY_000 — rim BOOST pass #3 (WB-17, THE EXPERIENCE PASS).

The WB-16 art-director audit (six-batch VLM sweep over the whole golden
path) still reads the protagonist as a dark silhouette in the deepest
rooms — the boss arena, the chantry back, the archive stacks — and the
enemies flatten into the floor beside him. The WB-7 rims (player 0.44)
kept the edge readable but the DARK rooms grew faster than the rim.

This pass lands the third bake. Same compound-delta math as WB-7: edge
pixels already carry m1, so m2 = (M - m1) / (1 - m1) lands exactly on M.

Targets M (from WB-7's m1):
  player 0.44 -> 0.58    hollow 0.32 -> 0.38    oren 0.32 -> 0.36
  penitent 0.34 -> 0.40  censor 0.40 -> 0.42    null_children 0.34 -> 0.38
  believers 0.40 -> 0.44 bound_martyr 0.42 -> 0.46
"""
import os
import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = "/home/z/entity000/art/characters"

# set -> (rim rgb, WB-7 strength m1, NEW target M)
TINTS = {
    "player":        ((222, 209, 178), 0.44, 0.58),
    "oren":          ((209, 199, 174), 0.32, 0.36),
    "penitent":      ((184, 199, 217), 0.34, 0.40),
    "censor":        ((128, 217, 219), 0.40, 0.42),
    "hollow":        ((204, 194, 168), 0.32, 0.38),
    "null_children": ((158, 141, 204), 0.34, 0.38),
    "believers":     ((219, 189, 133), 0.40, 0.44),
    "bound_martyr":  ((219, 184, 92),  0.42, 0.46),
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
