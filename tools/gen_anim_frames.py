#!/usr/bin/env python3
"""ENTITY_000 — Visual Pass 3: programmatic micro-motion frames.

The AI image-edit redraws overshot pose deltas (silhouette IoU 0.50 on the
censor, +53% brightness on the penitent), so the subtle idle layers are
synthesized from the APPROVED painted bases instead — cel-style transforms
(bob / lean / ghost / slice-glitch) that guarantee pixel identity:

  censor       idle_1  bob up 2px + top lean +3px (forward drift)
               idle_2  bob up 1px + top lean -3px (back drift) + cyan rim
  penitent     idle_1  ghost flicker: desat 12% + cyan ghost offset (2,1)
  oren         idle_1  micro-bow: 1.2 deg rotation about bottom-center + 1px
  null_child   idle_2  VHS slice glitch: 3 displaced bands + cyan scanline

Run after art_pipeline.py (frames inherit its common bottom-center canvas).
"""
import os
import numpy as np
from PIL import Image

ROOT = "/home/z/entity000/art/characters"


def load(p):
    return np.array(Image.open(p).convert("RGBA")).astype(np.float64)


def save(arr, p):
    Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGBA").save(p)


def shift_rows(arr, dx_per_row_from_top):
    """Horizontal shear: row y shifts by dx * (1 - y/h) (top rows move most)."""
    h, w = arr.shape[:2]
    out = np.zeros_like(arr)
    for y in range(h):
        dx = int(round(dx_per_row_from_top * (1.0 - y / (h - 1))))
        if dx == 0:
            out[y] = arr[y]
        elif dx > 0:
            out[y, dx:] = arr[y, :w - dx]
        else:
            out[y, :w + dx] = arr[y, -dx:]
    return out


def translate(arr, dx=0, dy=0):
    h, w = arr.shape[:2]
    out = np.zeros_like(arr)
    x0, x1 = max(0, dx), min(w, w + dx)
    y0, y1 = max(0, dy), min(h, h + dy)
    if x1 > x0 and y1 > y0:
        out[y0:y1, x0:x1] = arr[y0 - dy:y1 - dy, x0 - dx:x1 - dx]
    return out


def desaturate(arr, amt):
    g = arr[..., :3].mean(axis=2, keepdims=True)
    arr[..., :3] = arr[..., :3] * (1 - amt) + g * amt
    return arr


def rim_tint(arr, amt):
    """Tint only silhouette EDGE pixels toward cold cyan (rim glow)."""
    from scipy import ndimage
    a = arr[..., 3] > 128
    edge = a & ~ndimage.binary_erosion(a)
    m = edge * (arr[..., 3] / 255.0) * amt  # (h, w)
    for i, v in enumerate((110.0, 215.0, 245.0)):
        arr[..., i] = arr[..., i] * (1 - m) + v * m
    return arr


def cyan_tint_alpha(arr, amt):
    """Tint opaque pixels toward cold cyan, weighted by opacity."""
    a = (arr[..., 3] / 255.0) * amt  # (h, w)
    for i, v in enumerate((110.0, 215.0, 245.0)):
        arr[..., i] = arr[..., i] * (1 - a) + v * a
    return arr


def ghost_under(arr, dx, dy, strength):
    """Cold-cyan offset ghost composited over the base."""
    ghost = cyan_tint_alpha(arr.copy(), 0.75)
    ghost[..., 3] *= strength
    g = translate(ghost, dx, dy)
    a1 = arr[..., 3:4] / 255.0
    a2 = g[..., 3:4] / 255.0
    ao = np.clip(a1 + a2 * (1 - a1), 0, 1)
    out = arr * a1 + g * a2 * (1 - a1)
    out[..., :3] = np.where(ao > 0, out[..., :3] / np.maximum(ao, 1e-6), 0)
    out[..., 3:4] = ao * 255.0
    return out


def rotate_about(arr, deg, cx, cy):
    im = Image.fromarray(arr.astype(np.uint8), "RGBA")
    im = im.rotate(deg, resample=Image.BICUBIC, center=(cx, cy), expand=False)
    return np.array(im).astype(np.float64)


def slice_glitch(arr, bands, scan_y, scan_h=3, tint=0.85):
    """bands: [(y0f, y1f, dx)]; displace horizontal slices; cyan scanline band."""
    h, w = arr.shape[:2]
    out = arr.copy()
    for y0f, y1f, dx in bands:
        y0, y1 = int(h * y0f), int(h * y1f)
        seg = out[y0:y1]
        out[y0:y1] = translate(seg, dx, 0)
    y0 = int(h * scan_y)
    band = cyan_tint_alpha(out[y0:y0 + scan_h].copy(), tint)
    band[..., 3] = np.minimum(band[..., 3] * 1.0 + 40, 255)
    out[y0:y0 + scan_h] = band
    return out


def main():
    # --- CENSOR: 3-frame uncanny sway --------------------------------------
    # Pure sway (no rim tint — censor.gd already draws cyan afterimage trails
    # and a 17Hz modulate flicker procedurally on top; sprite-level rim read
    # as a jarring state change in QA).
    p = os.path.join(ROOT, "censor", "idle_0.png")
    base = load(p)
    f1 = shift_rows(translate(base, 0, -2), 2)
    f2 = shift_rows(translate(base, 0, -1), -2)
    save(f1, os.path.join(ROOT, "censor", "idle_1.png"))
    save(f2, os.path.join(ROOT, "censor", "idle_2.png"))
    print("censor: idle_1 (fwd drift), idle_2 (back drift)")

    # --- PENITENT: flicker ghost -------------------------------------------
    p = os.path.join(ROOT, "penitent", "idle_0.png")
    base = load(p)
    f1 = ghost_under(desaturate(translate(base, 0, -1), 0.12), 2, 1, 0.35)
    save(f1, os.path.join(ROOT, "penitent", "idle_1.png"))
    print("penitent: idle_1 (ghost flicker)")

    # --- OREN: micro-bow ----------------------------------------------------
    p = os.path.join(ROOT, "oren", "idle_0.png")
    base = load(p)
    h, w = base.shape[:2]
    f1 = translate(rotate_about(base, 1.2, w / 2.0, h - 1), 0, 1)
    save(f1, os.path.join(ROOT, "oren", "idle_1.png"))
    print("oren: idle_1 (micro-bow)")

    # --- NULL CHILD: third glitch variant ----------------------------------
    p = os.path.join(ROOT, "null_children", "idle_0.png")
    base = load(p)
    f2 = slice_glitch(base, [(0.18, 0.30, 4), (0.48, 0.56, -3), (0.72, 0.82, 2)], 0.60, tint=0.6)
    save(f2, os.path.join(ROOT, "null_children", "idle_2.png"))
    print("null_children: idle_2 (slice glitch)")

    print("SYNTH DONE")


if __name__ == "__main__":
    main()
