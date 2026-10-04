#!/usr/bin/env python3
"""ENTITY_000 — Visual Pass 4: the animation enrichment.

Cel-style transforms synthesized from the APPROVED painted bases (same
method as the accepted gen_anim_frames.py — pixel identity guaranteed,
no AI redraw drift). New frames per set:

  player      idle 2->4 (breath cycle: lift / settle)
              walk 4->8 (interleaved mid-stride lifts — double cadence
              without inventing new strides)
              jump 1->2, fall 1->2 (air pulse), hurt 1->2 (recoil echo),
              observe 1->2 (lean-in read), roll 1->4 (true tumble: the
              curled ball re-centered and rotated about its own center)
              attack1/2/3 2->3 (follow-through: extrapolates the REAL
              motion vector measured between the two existing frames)
  hollow      idle 2->4 (slow sway), telegraph 1->2 (coil), lunge 2->3
  believers   kneel 1->2 (prayer breath), strike 1->2 (carry-through),
              walk 4->6 (denser cadence)
  oren        idle 2->4 (bow cycle: bow / counter / lift)
  penitent    idle 2->3 (deeper ghost flicker)
  bound_martyr p1/p2/p3 1->2 (straining breath sway)

Run after the standard pipeline. NOT idempotent for walk/believer-walk
(re-generated frames feed the next pass) — `git checkout -- art/characters`
first if re-running. Frames inherit the shared bottom-center canvas of
their animation (except roll, which migrates to a square canvas whose
rotation pivot is the ball's own center, ball resting on the canvas
bottom = the feet line).
"""
import os
import numpy as np
from PIL import Image

ROOT = "/home/z/entity000/art/characters"


def load(p):
    return np.array(Image.open(p).convert("RGBA")).astype(np.float64)


def save(arr, p):
    Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGBA").save(p)


def translate(arr, dx=0, dy=0):
    h, w = arr.shape[:2]
    out = np.zeros_like(arr)
    x0, x1 = max(0, dx), min(w, w + dx)
    y0, y1 = max(0, dy), min(h, h + dy)
    if x1 > x0 and y1 > y0:
        out[y0:y1, x0:x1] = arr[y0 - dy:y1 - dy, x0 - dx:x1 - dx]
    return out


def shift_rows(arr, dx_top):
    """Shear: row y shifts by dx_top * (1 - y/h) — top rows move most."""
    h, w = arr.shape[:2]
    out = np.zeros_like(arr)
    for y in range(h):
        dx = int(round(dx_top * (1.0 - y / (h - 1))))
        if dx == 0:
            out[y] = arr[y]
        elif dx > 0:
            out[y, dx:] = arr[y, :w - dx]
        else:
            out[y, :w + dx] = arr[y, -dx:]
    return out


def desaturate(arr, amt):
    g = arr[..., :3].mean(axis=2, keepdims=True)
    arr[..., :3] = arr[..., :3] * (1 - amt) + g * amt
    return arr


def cyan_tint_alpha(arr, amt):
    a = (arr[..., 3] / 255.0) * amt
    for i, v in enumerate((110.0, 215.0, 245.0)):
        arr[..., i] = arr[..., i] * (1 - a) + v * a
    return arr


def ghost_under(arr, dx, dy, strength):
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


def row_centroids(arr):
    """Per-row alpha-weighted x centroid (only rows with mass)."""
    h = arr.shape[0]
    xs, ys, ms = [], [], []
    for y in range(h):
        a = arr[y, :, 3]
        m = float(a.sum())
        if m > 200.0:
            xs.append(float((a * np.arange(arr.shape[1])).sum()) / m)
            ys.append(y)
            ms.append(m)
    return np.array(xs), np.array(ys), np.array(ms)


def motion_vector(a0, a1):
    """Measured pose delta between two frames: (dx_total, top_shift).

    dx_total   — mass-weighted centroid x drift
    top_shift  — centroid x drift of the upper half minus lower half
                 (the lean / shear component)
    """
    x0, y0, m0 = row_centroids(a0)
    x1, y1, m1 = row_centroids(a1)
    cx0 = float((x0 * m0).sum() / m0.sum()) if m0.sum() > 0 else 0.0
    cx1 = float((x1 * m1).sum() / m1.sum()) if m1.sum() > 0 else 0.0
    dx_total = cx1 - cx0
    ymid = float(np.median(y0)) if len(y0) else 0.0
    t0 = x0[y0 < ymid]; b0 = x0[y0 >= ymid]
    t1 = x1[y1 < ymid]; b1 = x1[y1 >= ymid]
    top_shift = 0.0
    if len(t0) and len(t1):
        top_shift = float(t1.mean() - t0.mean()) - (float(b1.mean() - b0.mean()) if len(b1) and len(b0) else 0.0)
    return dx_total, top_shift


def follow_through(a0, a1, k=0.5, max_dx=3, max_sh=3):
    """Frame 3 of an attack: extrapolate the measured motion by k."""
    dx, sh = motion_vector(a0, a1)
    dx = int(np.clip(round(dx * k), -max_dx, max_dx))
    sh = int(np.clip(round(sh * k * 0.8), -max_sh, max_sh))
    return shift_rows(translate(a1, dx, 0), sh)


def alpha_bbox(arr):
    ys, xs = np.where(arr[..., 3] > 12)
    if len(xs) == 0:
        return 0, 0, arr.shape[1] - 1, arr.shape[0] - 1
    return int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())


def recenter_square(arr, side):
    """Pad/crop to (side, side) with the alpha-bbox CENTER at canvas center."""
    x0, y0, x1, y1 = alpha_bbox(arr)
    cx, cy = (x0 + x1) / 2.0, (y0 + y1) / 2.0
    h, w = arr.shape[:2]
    out = np.zeros((side, side, 4), dtype=np.float64)
    # position source so that (cx, cy) lands at (side/2, side/2)
    ox = int(round(side / 2.0 - cx))
    oy = int(round(side / 2.0 - cy))
    sx0, sy0 = max(0, -ox), max(0, -oy)
    sx1, sy1 = min(w, side - ox), min(h, side - oy)
    if sx1 > sx0 and sy1 > sy0:
        out[sy0 + oy:sy1 + oy, sx0 + ox:sx1 + ox] = arr[sy0:sy1, sx0:sx1]
    return out


def P(*a):
    return os.path.join(ROOT, *a)


def main():
    # ------------------------------------------------------------- PLAYER
    # idle breath cycle: lift (inhale apex) + settle (exhale bottom)
    base = load(P("player", "idle_0.png"))
    lift = shift_rows(translate(base, 0, -1), -1.4)
    settle = shift_rows(translate(base, 0, 0), 1.6)
    save(lift, P("player", "idle_2.png"))
    save(settle, P("player", "idle_3.png"))
    print("player: idle_2 (inhale lift), idle_3 (exhale settle)")

    # walk 4 -> 8: interleave mid-stride lifts (contact, lift, contact, lift...)
    old = [load(P("player", "walk_%d.png" % i)) for i in range(4)]
    seq = []
    for i in range(4):
        seq.append(old[i])
        seq.append(shift_rows(translate(old[i], 0, -2), 1.2))
    for i, fr in enumerate(seq):
        save(fr, P("player", "walk_%d.png" % i))
    print("player: walk 4 -> 8 (interleaved mid-stride lifts)")

    # air poses: pulse variants
    j = load(P("player", "jump_0.png"))
    save(shift_rows(translate(j, 0, -1), -1.5), P("player", "jump_1.png"))
    f = load(P("player", "fall_0.png"))
    save(shift_rows(translate(f, 0, 1), 1.8), P("player", "fall_1.png"))
    print("player: jump_1 / fall_1 (air pulse)")

    # hurt recoil echo
    hu = load(P("player", "hurt_0.png"))
    dxh, shh = motion_vector(load(P("player", "idle_0.png")), hu)
    save(shift_rows(translate(hu, int(np.clip(round(dxh * 0.5), -3, 3)), 0),
                    int(np.clip(round(shh * 0.6), -3, 3))), P("player", "hurt_1.png"))
    print("player: hurt_1 (recoil echo)")

    # observe lean-in read
    ob = load(P("player", "observe_0.png"))
    save(shift_rows(translate(ob, 0, -1), -1.2), P("player", "observe_1.png"))
    print("player: observe_1 (lean-in)")

    # attacks: measured follow-through frame
    for atk in ("attack1", "attack2", "attack3"):
        a0 = load(P("player", "%s_0.png" % atk))
        a1 = load(P("player", "%s_1.png" % atk))
        save(follow_through(a0, a1), P("player", "%s_2.png" % atk))
    print("player: attack1/2/3 _2 (measured follow-through)")

    # roll: true tumble — square canvas, rotation pivots on the ball's OWN
    # center, ball bottom resting on the canvas bottom (the feet line)
    r0 = load(P("player", "roll_0.png"))
    x0, y0, x1, y1 = alpha_bbox(r0)
    bw, bh = x1 - x0 + 1, y1 - y0 + 1
    side = int(max(bw, bh)) + 10
    bcx, bcy = side / 2.0, side - bh / 2.0
    hh, ww = r0.shape[:2]
    canvas = np.zeros((side, side, 4))
    ox = int(round(bcx - (x0 + x1) / 2.0))
    oy = int(round(bcy - (y0 + y1) / 2.0))
    sx0, sy0 = max(0, -ox), max(0, -oy)
    sx1, sy1 = min(ww, side - ox), min(hh, side - oy)
    canvas[sy0 + oy:sy1 + oy, sx0 + ox:sx1 + ox] = r0[sy0:sy1, sx0:sx1]
    for i, deg in enumerate((0, -90, 180, 90)):
        fr = canvas if deg == 0 else rotate_about(canvas, deg, bcx, bcy)
        save(fr, P("player", "roll_%d.png" % i))
    print("player: roll 1 -> 4 (pivot-on-center tumble, %dpx)" % side)

    # ------------------------------------------------------------- HOLLOW
    h0 = load(P("hollow", "idle_0.png"))
    save(shift_rows(translate(h0, 0, -1), 2.0), P("hollow", "idle_2.png"))
    save(shift_rows(translate(h0, 0, 0), -2.2), P("hollow", "idle_3.png"))
    t0 = load(P("hollow", "telegraph_0.png"))
    save(shift_rows(translate(t0, 0, 1), 2.4), P("hollow", "telegraph_1.png"))
    l1 = load(P("hollow", "lunge_1.png"))
    save(shift_rows(translate(l1, 0, 1), -2.4), P("hollow", "lunge_2.png"))
    print("hollow: idle_2/3 (sway), telegraph_1 (coil), lunge_2 (settle)")

    # ------------------------------------------------------------- BELIEVERS
    k0 = load(P("believers", "kneel_0.png"))
    save(shift_rows(translate(k0, 0, -1), 1.2), P("believers", "kneel_1.png"))
    s0 = load(P("believers", "strike_0.png"))
    dxs, shs = motion_vector(load(P("believers", "walk_0.png")), s0)
    save(shift_rows(translate(s0, int(np.clip(round(dxs * 0.4), -3, 3)), 0),
                    int(np.clip(round(shs * 0.5), -3, 3))), P("believers", "strike_1.png"))
    bw = [load(P("believers", "walk_%d.png" % i)) for i in range(4)]
    bseq = [bw[0], shift_rows(translate(bw[0], 0, -2), 1.0),
            bw[1], bw[2], shift_rows(translate(bw[2], 0, -2), 1.0), bw[3]]
    for i, fr in enumerate(bseq):
        save(fr, P("believers", "walk_%d.png" % i))
    print("believers: kneel_1 (breath), strike_1 (carry), walk 4 -> 6")

    # ------------------------------------------------------------- OREN
    o0 = load(P("oren", "idle_0.png"))
    h, w = o0.shape[:2]
    counter = translate(rotate_about(o0, -1.1, w / 2.0, h - 1), 0, 0)
    lift = shift_rows(translate(o0, 0, -1), -0.9)
    save(counter, P("oren", "idle_2.png"))
    save(lift, P("oren", "idle_3.png"))
    print("oren: idle_2 (counter-bow), idle_3 (breath lift)")

    # ------------------------------------------------------------- PENITENT
    p0 = load(P("penitent", "idle_0.png"))
    deep = ghost_under(desaturate(translate(p0, 0, -1), 0.18), -2, -1, 0.45)
    save(deep, P("penitent", "idle_2.png"))
    print("penitent: idle_2 (deep ghost flicker)")

    # ------------------------------------------------------------- MARTYR
    for ph in ("p1", "p2", "p3"):
        m0 = load(P("bound_martyr", "%s_0.png" % ph))
        save(shift_rows(translate(m0, 0, -1), 1.6), P("bound_martyr", "%s_1.png" % ph))
    print("bound_martyr: p1/p2/p3 _1 (straining breath)")

    print("SYNTH DONE")


if __name__ == "__main__":
    main()
