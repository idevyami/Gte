#!/usr/bin/env python3
"""ENTITY_000 — rim BOOST pass (WB-7).

The world grew six layers richer (WB-2..WB-6); the actors' baked rims
stayed at WB-4 strength and the VLM art-director audit now reads the
protagonist as camouflaged. This pass DEEPENS every set's rim to the new
targets. Baking compounds: edge pixels already carry strength m1 from
WB-4, so this pass applies the exact DELTA m2 = (M - m1) / (1 - m1)
to land on the target M in one additional bake. Alpha masks are
unchanged by baking, so the edge band geometry is identical and the
composition is exact.

Targets M (from WB-4's m1):
  player 0.30 -> 0.44   oren 0.22 -> 0.32   penitent 0.24 -> 0.34
  censor 0.32 -> 0.40   hollow 0.21 -> 0.32 null_children 0.25 -> 0.34
  believers 0.30 -> 0.40  bound_martyr 0.32 -> 0.42
"""
import os
import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = "/home/z/entity000/art/characters"

# set -> (rim rgb, WB-4 strength m1, NEW target M)
TINTS = {
    "player":        ((222, 209, 178), 0.30, 0.44),
    "oren":          ((209, 199, 174), 0.22, 0.32),
    "penitent":      ((184, 199, 217), 0.24, 0.34),
    "censor":        ((128, 217, 219), 0.32, 0.40),
    "hollow":        ((204, 194, 168), 0.21, 0.32),
    "null_children": ((158, 141, 204), 0.25, 0.34),
    "believers":     ((219, 189, 133), 0.30, 0.40),
    "bound_martyr":  ((219, 184, 92),  0.32, 0.42),
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
