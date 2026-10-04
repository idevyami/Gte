#!/usr/bin/env python3
"""ENTITY_000 — Visual Pass 5: the system's own movement.

Cel-style transforms synthesized from the APPROVED painted bases (same
method as the accepted p4 pass — pixel identity guaranteed, no AI redraw
drift). New frames per set:

  censor        idle 3->6 (hover bob: rise / apex lean / settle echo)
                arrive 0->4 (vertical unfurl about the feet anchor:
                0.38 / 0.64 / 0.90 / 1.06-over-squash, each with a cyan
                assembly ghost that fades as the body insists)
                reach 0->3 (the correction touch: forward lean about the
                feet, top shear, trailing ghost behind the lunge)
  null_children idle 3->6 (breath bob + tilt sway)
                walk 0->4 (glitch-step: lean / pass / counter-lean / pass,
                cyan phase-ghosts alternating sides — a record skipping
                while it walks)

All frames keep the shared canvas of their set (bottom-center anchor).
NOT idempotent — `git checkout -- art/characters/censor art/characters/null_children`
first if re-running.
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


def cyan_tint_alpha(arr, amt):
    a = (arr[..., 3] / 255.0) * amt
    for i, v in enumerate((110.0, 215.0, 245.0)):
        arr[..., i] = arr[..., i] * (1 - a) + v * a
    return arr


def ghost_under(arr, dx, dy, strength):
    """Cyan echo of the body offset by (dx, dy), composited beneath."""
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


def scale_y_about_bottom(arr, sy):
    """Vertical scale about the BOTTOM-CENTER anchor (the feet line):
    the body grows upward out of its own ground point. Alpha-safe."""
    h, w = arr.shape[:2]
    im = Image.fromarray(arr.astype(np.uint8), "RGBA")
    nh = max(2, int(round(h * sy)))
    im2 = im.resize((w, nh), resample=Image.BICUBIC)
    out = np.zeros((h, w, 4), dtype=np.float64)
    if nh >= h:
        # crop from the top (feet stay glued to the bottom row)
        y0 = nh - h
        out[:] = np.array(im2)[y0:y0 + h]
    else:
        # pad above (body rises from the anchor)
        a2 = np.array(im2).astype(np.float64)
        out[h - nh:] = a2
    return out


def scale_x_about_center(arr, sx):
    h, w = arr.shape[:2]
    im = Image.fromarray(arr.astype(np.uint8), "RGBA")
    nw = max(2, int(round(w * sx)))
    im2 = im.resize((nw, h), resample=Image.BICUBIC)
    out = np.zeros((h, w, 4), dtype=np.float64)
    a2 = np.array(im2).astype(np.float64)
    x0 = (w - nw) // 2
    if nw >= w:
        out[:] = a2[x0:x0 + w]
    else:
        out[:, x0:x0 + nw] = a2
    return out


def P(*a):
    return os.path.join(ROOT, *a)


def main():
    # ------------------------------------------------------------ CENSOR
    # idle 3 -> 6: the hover bob — rise, apex lean, settle echo.
    idl = [load(P("censor", "idle_%d.png" % i)) for i in range(3)]
    h, w = idl[0].shape[:2]
    # 3: rise (whole body up 2px, bar drifts with it)
    rise = translate(idl[1], 0, -2)
    # 4: apex lean (up 1, top shear 1.6 — the head of the bar leads)
    apex = shift_rows(translate(idl[2], 0, -1), 1.6)
    # 5: settle echo (down 1, counter shear — the exhale)
    settle = shift_rows(translate(idl[0], 0, 1), -1.2)
    save(rise, P("censor", "idle_3.png"))
    save(apex, P("censor", "idle_4.png"))
    save(settle, P("censor", "idle_5.png"))
    print("censor: idle 3 -> 6 (rise / apex lean / settle echo)")

    # arrive 0->4: the unfurl — it does not walk in, it INSISTS into place.
    base = idl[0]
    specs = [
        (0.38, 0.55, 0),   # (scale_y, ghost_strength, ghost_dx)
        (0.64, 0.38, -3),
        (0.90, 0.22, -5),
        (1.06, 0.12, -6),  # overshoot: slightly too tall before settling
    ]
    for i, (sy, gs, gx) in enumerate(specs):
        fr = scale_y_about_bottom(base, sy)
        fr = ghost_under(fr, gx, 2 * i - 2, gs)
        save(fr, P("censor", "arrive_%d.png" % i))
    print("censor: arrive 4 (unfurl about the feet anchor, assembly ghosts)")

    # reach 0->3: the correction touch — leans INTO you.
    for i, (deg, sh, gs) in enumerate([(5.0, 3.0, 0.20), (12.0, 6.0, 0.30), (18.0, 9.0, 0.38)]):
        fr = rotate_about(base, -deg, w / 2.0, h - 6.0)
        fr = shift_rows(fr, -sh)
        fr = ghost_under(fr, 4 + i * 2, 0, gs)
        save(fr, P("censor", "reach_%d.png" % i))
    print("censor: reach 3 (forward lean about the feet, trailing ghosts)")

    # ------------------------------------------------------ NULL CHILDREN
    # idle 3 -> 6: breath bob + tilt sway.
    nidl = [load(P("null_children", "idle_%d.png" % i)) for i in range(3)]
    nh, nw = nidl[0].shape[:2]
    # 3: tilt left (rotate 2° about feet, ghost whisper)
    n3 = ghost_under(rotate_about(nidl[0], 2.0, nw / 2.0, nh - 4.0), -3, 0, 0.14)
    # 4: lift (breath apex — up 1)
    n4 = translate(nidl[1], 0, -1)
    # 5: tilt right + settle
    n5 = ghost_under(rotate_about(nidl[2], -2.0, nw / 2.0, nh - 4.0), 3, 1, 0.14)
    save(n3, P("null_children", "idle_3.png"))
    save(n4, P("null_children", "idle_4.png"))
    save(n5, P("null_children", "idle_5.png"))
    print("null_children: idle 3 -> 6 (tilt sway + breath)")

    # walk 0->4: the glitch-step — a record skipping while it walks.
    # lean / pass / counter-lean / pass, phase ghosts alternating sides.
    wspecs = [
        (nidl[0], 5.0, 2.2, +4, 0.20),   # lean into step, ghost behind
        (nidl[1], 0.0, 0.0, -5, 0.16),   # passing, ghost opposite
        (nidl[0], -5.0, -2.2, -4, 0.20), # counter lean
        (nidl[2], 0.0, 0.0, +5, 0.16),   # passing, ghost opposite
    ]
    for i, (src, deg, sh, gx, gs) in enumerate(wspecs):
        fr = rotate_about(src, deg, nw / 2.0, nh - 4.0)
        if sh != 0.0:
            fr = shift_rows(fr, sh)
        fr = ghost_under(fr, gx, 0, gs)
        save(fr, P("null_children", "walk_%d.png" % i))
    print("null_children: walk 4 (glitch-step, alternating phase ghosts)")

    print("PASS 5 complete: censor 3->16, null_children 3->10")


if __name__ == "__main__":
    main()
