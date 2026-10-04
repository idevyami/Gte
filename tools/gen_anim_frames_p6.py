#!/usr/bin/env python3
"""ENTITY_000 — Visual Pass 6: THE PERFORMERS.

Cel-style transforms synthesized from the APPROVED painted bases (same
method as the accepted p4/p5 passes — pixel identity for interior pixels,
no AI redraw drift). New frames per set:

  hollow        walk  0->6 (stride cycle: alternating leg-band shear,
                          body bob, counter-swing arms, forward lean)
                hurt  0->2 (recoil: lean away, head snaps back)
                death 0->4 (the crumple: stun straighten -> buckle
                          forward -> collapse -> the heap)
  oren          talk  0->3 (head bob + the stamping hand accents)
                talk  0->3 (head bob + the stamping hand accents)
  believers     kneel 2->4 (the prayer deepens: bow + breath)
                hurt  0->2 (recoil, hood snaps back)
                death 0->4 (they fall to their knees, slump, go still)
  bound_martyr  p1/p2/p3 idles 2->4 each (sway + breath / strain /
                          tremble)
                death 1->3 (the sag: hangs, then folds)

All frames keep the shared canvas of their set (bottom-center anchor).
NOT idempotent — `git checkout -- art/characters/<set>` first if re-running.
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

def shear_band(arr, y0f, y1f, dx):
    """Shift only rows in [y0f*h, y1f*h) by dx px — the leg/robe band."""
    h, w = arr.shape[:2]
    out = arr.copy()
    y0 = int(round(y0f * h))
    y1 = int(round(y1f * h))
    for y in range(max(0, y0), min(h, y1)):
        if dx == 0:
            continue
        if dx > 0:
            out[y, dx:] = arr[y, :w - dx]
        else:
            out[y, :w + dx] = arr[y, -dx:]
    return out

def rotate_about(arr, deg, cx, cy):
    im = Image.fromarray(arr.astype(np.uint8), "RGBA")
    im = im.rotate(deg, resample=Image.BICUBIC, center=(cx, cy), expand=False)
    return np.array(im).astype(np.float64)

def scale_y_about_bottom(arr, sy):
    h, w = arr.shape[:2]
    im = Image.fromarray(arr.astype(np.uint8), "RGBA")
    nh = max(2, int(round(h * sy)))
    im2 = im.resize((w, nh), resample=Image.BICUBIC)
    out = np.zeros((h, w, 4), dtype=np.float64)
    if nh >= h:
        y0 = nh - h
        out[:] = np.array(im2)[y0:y0 + h]
    else:
        a2 = np.array(im2).astype(np.float64)
        out[h - nh:] = a2
    return out

def scale_y_about_top(arr, sy):
    """For HANGING bodies: the anchor is the TOP (the chains). A sag
    pulls the feet UP toward the hanging point — the weight wins."""
    h, w = arr.shape[:2]
    im = Image.fromarray(arr.astype(np.uint8), "RGBA")
    nh = max(2, int(round(h * sy)))
    im2 = im.resize((w, nh), resample=Image.BICUBIC)
    out = np.zeros((h, w, 4), dtype=np.float64)
    a2 = np.array(im2).astype(np.float64)
    out[0:min(h, nh)] = a2[0:min(h, nh)]
    return out

def scale_y_about_top(arr, sy):
    """For HANGING bodies: the anchor is the top (the chains). A sag
    pulls the feet UP toward the hanging point — the weight wins."""
    h, w = arr.shape[:2]
    im = Image.fromarray(arr.astype(np.uint8), "RGBA")
    nh = max(2, int(round(h * sy)))
    im2 = im.resize((w, nh), resample=Image.BICUBIC)
    out = np.zeros((h, w, 4), dtype=np.float64)
    a2 = np.array(im2).astype(np.float64)
    out[0:min(h, nh)] = a2[0:min(h, nh)]
    return out

def scale_x_about_center(arr, sx):
    h, w = arr.shape[:2]
    im = Image.fromarray(arr.astype(np.uint8), "RGBA")
    nw = max(2, int(round(w * sx)))
    im2 = im.resize((nw, h), resample=Image.BICUBIC)
    out = np.zeros((h, w, 4), dtype=np.float64)
    a2 = np.array(im2).astype(np.float64)
    if nw >= w:
        # widened: keep the CENTER of the widened body (source crop)
        s0 = (nw - w) // 2
        out[:] = a2[:, s0:s0 + w]
    else:
        x0 = (w - nw) // 2
        out[:, x0:x0 + nw] = a2
    return out

def P(*a):
    return os.path.join(ROOT, *a)


def main():
    # ============================================================= HOLLOW
    # walk 0->6: the stride the enemy never had. Leg band shears
    # alternately, body bobs, arms counter-swing, whole figure leans in.
    # (BOLD by law: at 43px of body width a shy shear reads as nothing —
    # the stride must survive gameplay zoom)
    idl = [load(P("hollow", "idle_%d.png" % i)) for i in range(4)]
    h, w = idl[0].shape[:2]
    # (base, leg_shear, bob_dy, top_lean, arm_shear)
    wspecs = [
        (idl[0], +8, -2, +3.4, -6),  # full reach: front leg out, body lifts
        (idl[1], +3, -3, +2.2, -2),  # pass: weight over the leg, highest
        (idl[2], -8,  0, +1.4, +6),  # counter reach: back leg swings through
        (idl[3], -3, -2, +2.6, +3),  # pass: settling
        (idl[1], +8, -2, +3.6, -6),  # full reach (base swap: the arms read)
        (idl[2], +3, -3, +1.8, +4),  # pass high
    ]
    for i, (src, ls, dy, tl, asw) in enumerate(wspecs):
        fr = shear_band(src, 0.55, 1.0, ls)          # the legs
        fr = shear_band(fr, 0.28, 0.55, int(round(asw)))  # the arms
        fr = shift_rows(fr, tl)                       # forward lean
        fr = translate(fr, 0, dy)                     # bob
        save(fr, P("hollow", "walk_%d.png" % i))
    print("hollow: walk 6 (stride cycle, counter-swing arms, lean)")

    # hurt 0->2: it registers the blow — leans away, head snaps back.
    # (magnitudes stay INSIDE the tight 43px canvas — no edge clipping)
    for i, (deg, sh, dy) in enumerate([(6.0, -4.0, 0), (8.0, -5.0, 1)]):
        fr = rotate_about(idl[1], deg, w / 2.0, h - 4.0)   # away from facing
        fr = shift_rows(fr, sh)
        fr = translate(fr, 0, dy)
        save(fr, P("hollow", "hurt_%d.png" % i))
    print("hollow: hurt 2 (recoil lean, head snap)")

    # death 0->4: stun -> buckle -> collapse -> prone.
    # NO squash-scaling (it destroys the engraved line work). Instead the
    # body ROTATES about its feet onto a 2.2x-wider shared canvas — the
    # head sweeps forward as it falls, pixel density preserved. The feet
    # stay at the canvas bottom-center, so the set anchor law holds.
    def widen(arr, cw):
        """Place arr on a cw-wide canvas, bottom-center anchored."""
        hh, ww = arr.shape[:2]
        out = np.zeros((hh, cw, 4), dtype=np.float64)
        x0 = (cw - ww) // 2
        out[:, x0:x0 + ww] = arr
        return out

    DW = w * 2  # 86px — a 92px body rotated 74° spans ~88px. Fits.
    d0 = translate(idl[0], 0, 1)                                  # stun: a 1px drop, rigid
    d1 = rotate_about(widen(idl[1], DW), 10.0, DW / 2.0, h - 4.0)  # buckles forward
    d2 = rotate_about(widen(idl[2], DW), 32.0, DW / 2.0, h - 4.0)  # going down
    d3 = rotate_about(widen(idl[3], DW), 58.0, DW / 2.0, h - 4.0)  # prone (almost flat)
    d3 = translate(d3, 0, 3)
    for i, fr in enumerate([d0, d1, d2, d3]):
        save(fr, P("hollow", "death_%d.png" % i))
    print("hollow: death 4 (stun / buckle / going down / prone — true rotation)")

    # =============================================================== OREN
    # (walk dropped — Oren never leaves his post; his life is the TALK set)
    oidl = [load(P("oren", "idle_%d.png" % i)) for i in range(4)]

    # talk 0->3: head bob + the stamping hand accents mid-speech.
    tspecs = [
        (oidl[0], 0, 0, 0.0),     # attentive rest
        (oidl[1], 0, -1, 1.2),    # head tips up (making a point)
        (oidl[2], 1, 0, 0.8),     # nod
        (oidl[3], 0, 1, 0.0),     # down-beat (the stamp lands)
    ]
    for i, (src, hdx, dy, tl) in enumerate(tspecs):
        fr = shear_band(src, 0.0, 0.22, hdx)   # the head band tips
        fr = shift_rows(fr, tl)
        fr = translate(fr, 0, dy)
        save(fr, P("oren", "talk_%d.png" % i))
    print("oren: talk 3 (head bob, stamp accents)")

    # ========================================================== BELIEVERS
    bidl = [load(P("believers", "kneel_%d.png" % i)) for i in range(2)]
    bw = bidl[0].shape[1]
    # kneel 2->4: the prayer deepens — bow lower, breath, hold, ease.
    k2 = shift_rows(translate(bidl[1], 0, 1), 2.4)   # bowed deep
    k3 = shift_rows(translate(bidl[0], 0, -1), 1.2)  # rising ease
    save(k2, P("believers", "kneel_2.png"))
    save(k3, P("believers", "kneel_3.png"))
    print("believers: kneel 2 -> 4 (the bow deepens)")

    # hurt 0->2: recoil, hood snaps back.
    for i, (deg, sh) in enumerate([(6.0, -4.0), (10.0, -6.0)]):
        fr = rotate_about(bidl[0], deg, bw / 2.0, bidl[0].shape[0] - 4.0)
        fr = shift_rows(fr, sh)
        save(fr, P("believers", "hurt_%d.png" % i))
    print("believers: hurt 2 (recoil)")

    # death 0->4: they do not simply fade — knees, slump, face-down, still.
    b0 = scale_y_about_bottom(translate(bidl[0], 0, 1), 1.03)  # the hit registers
    b1 = shift_rows(rotate_about(bidl[1], 8.0, bw / 2.0, bidl[1].shape[0] - 4.0), 5.0)
    b1 = scale_y_about_bottom(translate(b1, 0, 2), 0.88)      # sinks to knees
    b2 = scale_y_about_bottom(
        shift_rows(rotate_about(bidl[0], 18.0, bw / 2.0, bidl[0].shape[0] - 4.0), 9.0), 0.58)
    b2 = translate(b2, 0, 2)                                   # slumps forward
    b3 = scale_x_about_center(
        scale_y_about_bottom(translate(bidl[1], 0, 3), 0.42), 1.16)  # still
    for i, fr in enumerate([b0, b1, b2, b3]):
        save(fr, P("believers", "death_%d.png" % i))
    print("believers: death 4 (knees / slump / still)")

    # ======================================================= BOUND MARTYR
    # idles 2->4 per phase: the sway + the STRAIN SAG (the body is pulled
    # DOWN against its bonds — never scaled up, the halo must not clip)
    for ph, (sway_a, sway_b, sag) in enumerate(
            [(2.0, -2.0, 0.985), (2.6, -2.3, 0.975), (2.8, -2.6, 0.962)]):
        base = load(P("bound_martyr", "p%d_0.png" % (ph + 1)))
        mh, mw = base.shape[:2]
        # +2: the sway (phase-shifted tilt about the hanging point)
        f2 = rotate_about(base, sway_a, mw / 2.0, 6.0)
        # +3: the strain sag — scaled about the TOP (the chains): the feet
        # rise as the body compresses under its own weight
        f3 = scale_y_about_top(base, sag)
        f3 = scale_x_about_center(f3, 1.0 + (1.0 - sag) * 0.5)
        f3 = rotate_about(f3, sway_b, mw / 2.0, 6.0)
        save(f2, P("bound_martyr", "p%d_2.png" % (ph + 1)))
        save(f3, P("bound_martyr", "p%d_3.png" % (ph + 1)))
        print("bound_martyr: p%d idle 2 -> 4 (sway + strain sag)" % (ph + 1))

    # death 1->3: the sag — hangs, folds, rests.
    dbase = load(P("bound_martyr", "death_0.png"))
    dh, dw = dbase.shape[:2]
    m1 = scale_y_about_bottom(dbase, 0.86)                       # the weight takes it
    m1 = rotate_about(m1, 2.5, dw / 2.0, 6.0)
    m2 = scale_y_about_bottom(
        rotate_about(dbase, 6.0, dw / 2.0, 6.0), 0.66)           # folds
    for i, fr in enumerate([m1, m2]):
        save(fr, P("bound_martyr", "death_%d.png" % (i + 1)))
    print("bound_martyr: death 1 -> 3 (the sag)")

    print("PASS 6 complete: hollow 9->21, oren 4->8, believers 10->18, bound_martyr 13->21")


if __name__ == "__main__":
    main()
