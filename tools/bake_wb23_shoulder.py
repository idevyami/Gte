#!/usr/bin/env python3
"""ENTITY_000 — rim bake pass #5 (WB-23, THE FURNITURE YIELDS).

The figure-vs-architecture audit at the reliquary's busiest wall: the
crowd's own baked edge — a UNIFORM gold ring at 0.70 around a near-black
robe — parses as "ornate golden wheels", not people. A closed uniform
ring is an object grammar (wheel, medallion, gear); a person reads by
TOP-LIGHT: the lamp catches the crown and shoulders, the robe falls
away dark. This bake re-shapes the congregation's edge directionally:

  edge normal faces UP   (crown, hood, shoulder tops) -> M 0.70 (kept)
  edge normal horizontal (robe flanks)               -> M 0.42
  edge normal faces DOWN (hem, underside)             -> M 0.26

Math: the sprites currently carry the uniform WB-21 bake at m1 = 0.70
toward gold. Recover the original, then re-bake per-pixel with the
directional target M(n). The average edge margin stays >= the smoke
law's 0.25 step (sides keep a real presence; only the RING dies).
"""
import os
import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = "/home/z/entity000/art/characters"

GOLD = np.array([219.0, 189.0, 133.0])
M1 = 0.70            # the current uniform bake (WB-21)
M_TOP = 0.70         # crown/hood/shoulder tops keep the full strength
M_SIDE = 0.46        # the robe's flanks keep a presence
M_HEM = 0.28         # the hem lets go — the ring is broken by law


def directional_m(ny):
    """ny = the edge normal's y component in image coords (y down).
    ny < 0 faces up; ny > 0 faces down. Smooth taper between the three."""
    up = np.clip(-ny, 0.0, 1.0)          # 1 at crown, 0 at flanks
    down = np.clip(ny, 0.0, 1.0)         # 1 at hem
    side = 1.0 - up - down
    return M_TOP * up + M_SIDE * side + M_HEM * down


def bake(path):
    arr = np.array(Image.open(path).convert("RGBA")).astype(np.float64)
    a = arr[..., 3] > 128
    if not a.any():
        return False
    edge = a & ~ndimage.binary_erosion(a, iterations=2)
    if not edge.any():
        return False
    # edge normal = alpha gradient (points outward)
    gy, gx = np.gradient(a.astype(np.float64))
    ny = np.zeros_like(gy)
    nlen = np.sqrt(gx * gx + gy * gy)
    ok = nlen > 1e-6
    ny[ok] = gy[ok] / nlen[ok]
    # recover the pre-bake original: cur = orig*(1-m1) + gold*m1
    orig = (arr[..., :3] - GOLD * M1) / (1.0 - M1)
    # directional re-bake from the recovered original: lands exactly on M
    m = edge * (arr[..., 3] / 255.0) * directional_m(ny)
    out = orig * (1.0 - m[..., None]) + GOLD * m[..., None]
    arr[..., :3] = np.clip(out, 0, 255)
    Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGBA").save(path)
    return True


def main():
    d = os.path.join(ROOT, "believers")
    n = 0
    for fn in sorted(os.listdir(d)):
        if fn.endswith(".png"):
            if bake(os.path.join(d, fn)):
                n += 1
                print("baked", fn)
    print("done:", n, "sprites")


if __name__ == "__main__":
    main()
