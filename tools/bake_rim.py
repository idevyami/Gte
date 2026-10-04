#!/usr/bin/env python3
"""ENTITY_000 — bake the rim light into the character sprites.

The runtime rim shader never actually compiled on Godot 4.4 (MODULATE is a
Godot 3 built-in; the failure fell back silently to the plain sprite shader,
so every approved pass shipped with NO rim). A compiling custom canvas_item
shader would break the modulate chain (hurt flash, iframe blink, death fade)
— unacceptable for gameplay feedback.

So the rim is BAKED: every character frame's silhouette-edge pixels get a
subtle per-set tint (the same cel-transform guarantee as the rest of the
pipeline — palette-locked, pixel-identity for interior pixels).

Per-set tints mirror the shader's RIM_TINTS table. Run AFTER gen_anim_frames
passes (it processes every .png in each set dir). Idempotent-ish: re-running
deepens the tint — run on a clean checkout for exact results.
"""
import os
import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = "/home/z/entity000/art/characters"

# set -> (rim rgb, strength)
TINTS = {
    "player":       ((222, 209, 178), 0.30),
    "oren":         ((209, 199, 174), 0.22),
    "penitent":     ((184, 199, 217), 0.24),
    "censor":       ((128, 217, 219), 0.32),
    "hollow":       ((204, 194, 168), 0.21),
    "null_children":((158, 141, 204), 0.25),
    "believers":    ((219, 189, 133), 0.30),
    "bound_martyr": ((219, 184, 92),  0.32),
}


def bake(path, rgb, strength):
    arr = np.array(Image.open(path).convert("RGBA")).astype(np.float64)
    a = arr[..., 3] > 128
    if not a.any():
        return False
    # edge = opaque pixels adjacent to transparency (2px band)
    edge = a & ~ndimage.binary_erosion(a, iterations=2)
    m = edge * (arr[..., 3] / 255.0) * strength
    for i, v in enumerate(rgb):
        arr[..., i] = arr[..., i] * (1.0 - m) + v * m
    Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8)).save(path)
    return True


def main():
    for set_name, (rgb, strength) in TINTS.items():
        d = os.path.join(ROOT, set_name)
        if not os.path.isdir(d):
            continue
        n = 0
        for fn in sorted(os.listdir(d)):
            if fn.endswith(".png"):
                if bake(os.path.join(d, fn), rgb, strength):
                    n += 1
        print(f"{set_name}: rim baked into {n} frames (strength {strength})")
    print("RIM BAKE DONE")


if __name__ == "__main__":
    main()
