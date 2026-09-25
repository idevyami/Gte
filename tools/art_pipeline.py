#!/usr/bin/env python3
"""
ENTITY_000 — art pipeline: raw AI images -> game-ready, palette-locked sprites.

Policy (per the Visual Reconstruction brief): every AI asset must be
SELECTED, CORRECTED, CROPPED/COMPOSED, STYLISTICALLY UNIFIED, PALETTE
CONTROLLED and INTEGRATED. Raw AI output never enters res:// directly.

Steps per character frame:
  1. cutout     — border-connected background removal (scipy flood + labeling;
                  keep the main component plus near-attached features like the
                  Martyr's floating halo)
  2. crop       — alpha bbox; baseline = feet (bottom edge)
  3. unify      — downscale (LANCZOS) to game scale, then quantize to the
                  locked E0 ramp via nearest-color in CIELAB
  4. de-halo    — semi-transparent edge pixels darkened toward void
  5. compose    — all frames of one animation padded to a shared canvas,
                  bottom-center anchored (feet on the baseline)
  6. QA sheets  — contact sheets on the game's panel color for VLM review

Idempotent: re-run any time; missing raws are reported, never fatal.
Usage: python3 tools/art_pipeline.py [character|props|env]
"""
import sys, os
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance, ImageFont
import scipy.ndimage as ndi

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RAW = os.path.join(ROOT, "art", "raw")

# ---------------------------------------------------------------- locked ramp
def _h(s):
    s = s.lstrip("#")
    return tuple(int(s[i:i+2], 16) for i in (0, 2, 4))

_BASE = {
    "VOID": "#070708", "SHADOW": "#0d0d0f", "CHARCOAL": "#141416", "ASH": "#2b2b2e",
    "DIRTY_STONE": "#4a463f", "BONE": "#cfc8b8", "PARCH": "#a89f8c", "DIM": "#857d6c",
    "BLOOD": "#6d1a22", "CRIMSON": "#83322b", "GOLD": "#b08d3e", "VIOLET": "#3b2f4a",
    "CYAN": "#7fd8d8",
}
def _mix(c, other, k):
    return tuple(int(round(c[i] + (other[i] - c[i]) * k)) for i in range(3))
BLACK, WHITE = (4, 4, 5), (232, 226, 210)

RAMP = []
for _name, _hex in _BASE.items():
    c = _h(_hex)
    RAMP += [_mix(c, BLACK, 0.42), _mix(c, BLACK, 0.22), c,
             _mix(c, WHITE, 0.22), _mix(c, WHITE, 0.42)]
RAMP += [BLACK, _mix(BLACK, WHITE, 0.06), WHITE]
RAMP = sorted(set(RAMP))

def _srgb_to_lab(arr):  # arr float Nx3 in 0..1
    lin = np.where(arr <= 0.04045, arr / 12.92, ((arr + 0.055) / 1.055) ** 2.4)
    m = np.array([[0.4124, 0.3576, 0.1805],
                  [0.2126, 0.7152, 0.0722],
                  [0.0193, 0.0720, 0.9505]])
    xyz = lin @ m.T
    xyz /= np.array([0.95047, 1.0, 1.08883])
    f = np.where(xyz > 0.008856, np.cbrt(xyz), 7.787 * xyz + 16.0 / 116.0)
    L = 116.0 * f[:, 1] - 16.0
    a = 500.0 * (f[:, 0] - f[:, 1])
    b = 200.0 * (f[:, 1] - f[:, 2])
    return np.stack([L, a, b], axis=1)

_RAMP_LAB = _srgb_to_lab(np.array(RAMP, dtype=float) / 255.0)

def quantize_rgba(img):
    """Map RGB onto the locked ramp (alpha preserved)."""
    rgb = np.asarray(img.convert("RGBA"), dtype=np.uint8)
    h, w = rgb.shape[:2]
    px = rgb[:, :, :3].reshape(-1, 3).astype(float) / 255.0
    lab = _srgb_to_lab(px)
    d = ((lab[:, None, :] - _RAMP_LAB[None, :, :]) ** 2).sum(axis=2)
    idx = np.argmin(d, axis=1)
    out = np.array(RAMP, dtype=np.uint8)[idx].reshape(h, w, 3)
    out_img = Image.fromarray(out, "RGB").convert("RGBA")
    out_img.putalpha(Image.fromarray(rgb[:, :, 3]))
    return out_img

# ---------------------------------------------------------------- cutout
def cutout(img, thresh=16, erode=0):
    """Remove the border-connected background; soft-edged alpha result.
    Auto-detects flat gray backgrounds (used for all character art) and uses
    a generous threshold + 1px erosion to trim gray-contaminated rims."""
    im = img.convert("RGB")
    w, h = im.size
    px = im.load()
    border = []
    for x in range(0, w, 4):
        border.append(px[x, 0]); border.append(px[x, h - 1])
    for y in range(0, h, 4):
        border.append(px[0, y]); border.append(px[w - 1, y])
    bcol = tuple(int(np.median([c[i] for c in border])) for i in range(3))
    gray_bg = sum(bcol) / 3.0 > 80.0
    if gray_bg:
        thresh = 42
        erode = max(erode, 1)

    arr = np.asarray(im, dtype=np.int32)
    dist = np.sqrt(((arr - np.array(bcol)) ** 2).sum(axis=2))
    cand = dist < thresh

    bg = np.zeros_like(cand)
    bg[0, :] = cand[0, :]; bg[-1, :] = cand[-1, :]
    bg[:, 0] = cand[:, 0]; bg[:, -1] = cand[:, -1]
    bg = ndi.binary_propagation(bg, mask=cand)
    fg = ~bg
    if erode > 0:
        fg = ndi.binary_erosion(fg, iterations=erode)

    lab, n = ndi.label(fg)
    if n > 1:
        sizes = ndi.sum(fg, lab, range(1, n + 1))
        main = int(np.argmax(sizes)) + 1
        mb = ndi.find_objects(lab)[main - 1]
        grow = int(0.25 * max(mb[0].stop - mb[0].start, mb[1].stop - mb[1].start))
        region = np.zeros_like(fg)
        region[max(0, mb[0].start - grow):mb[0].stop + grow,
               max(0, mb[1].start - grow):mb[1].stop + grow] = True
        for i in range(1, n + 1):
            if i == main:
                continue
            comp = lab == i
            if sizes[i - 1] >= 30 and (comp & region).any():
                fg |= comp

    alpha = (fg * 255).astype(np.uint8)
    aimg = Image.fromarray(alpha).filter(ImageFilter.GaussianBlur(0.7))
    a = np.asarray(aimg).astype(np.int32)
    a = np.clip((a - 70) * 255 // 115, 0, 255).astype(np.uint8)
    out = im.convert("RGBA")
    out.putalpha(Image.fromarray(a))
    return out

# ---------------------------------------------------------------- frames
def process_frame(raw_path, target_h, thresh=16,
                  brighten=1.06, contrast=1.06, saturate=0.92):
    src = Image.open(raw_path).convert("RGB")
    rgba = cutout(src, thresh=thresh)
    bbox = rgba.getbbox()
    if bbox is None:
        return None
    rgba = rgba.crop(bbox)
    w, h = rgba.size
    nw = max(1, int(round(w * target_h / h)))
    rgba = rgba.resize((nw, target_h), Image.LANCZOS)

    a = rgba.getchannel("A")
    rgb = ImageEnhance.Brightness(rgba.convert("RGB")).enhance(brighten)
    rgb = ImageEnhance.Contrast(rgb).enhance(contrast)
    rgb = ImageEnhance.Color(rgb).enhance(saturate)
    rgba = rgb.convert("RGBA")
    rgba.putalpha(a)

    an = np.asarray(a, dtype=np.int16)
    arr = np.asarray(rgba).astype(np.int16)
    weak = (an > 6) & (an < 190)
    arr[weak, :3] = (arr[weak, :3] * 0.45).astype(np.int16)
    out = Image.fromarray(arr.astype(np.uint8))
    out.putalpha(a)
    return quantize_rgba(out)

def compose_set(frames, pad=2):
    """Pad frames to a shared canvas, bottom-center anchored."""
    W = max(f.size[0] for f in frames) + pad * 2
    H = max(f.size[1] for f in frames) + pad * 2
    out = []
    for f in frames:
        canvas = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        canvas.paste(f, ((W - f.size[0]) // 2, H - f.size[1]), f)
        out.append(canvas)
    return out, (W, H)

# ---------------------------------------------------------------- manifest
CHARACTERS = {
    "player": {
        "height": 72,
        "grade": {"brighten": 1.2, "contrast": 1.1},
        "anims": {
            "idle": ["player_idle_a", "player_idle_b"],
            "walk": ["player_walk_a", "player_walk_b", "player_walk_c", "player_walk_b"],
            "jump": ["player_jump"],
            "fall": ["player_fall"],
            "attack1": ["player_atk_windup", "player_atk_1"],
            "attack2": ["player_atk_windup", "player_atk_2"],
            "attack3": ["player_atk_windup", "player_atk_3"],
            "hurt": ["player_hurt"],
            "death": ["player_death_a", "player_death_b"],
            "interact": ["player_interact"],
            "observe": ["player_observe"],
            "roll": ["player_roll"],
        },
    },
    "bound_martyr": {
        "height": 160,
        "anims": {
            "p1": ["martyr_p1"],
            "p1_attack": ["martyr_p1", "martyr_p1_atk"],
            "p2": ["martyr_p2"],
            "p2_attack": ["martyr_p2", "martyr_p2_atk"],
            "p3": ["martyr_p3"],
            "p3_attack": ["martyr_p3", "martyr_p3_atk"],
            "death": ["martyr_death"],
        },
    },
    "hollow": {
        "height": 88,
        "grade": {"brighten": 1.08},
        "anims": {
            "idle": ["hollow_base"],
            "telegraph": ["hollow_telegraph"],
            "lunge": ["hollow_lunge"],
        },
    },
    "believers": {
        "height": 70,
        "anims": {
            "kneel": ["believer_kneel"],
            "walk": ["believer_stand"],
            "strike": ["believer_strike"],
        },
    },
    "censor": {
        "height": 128,
        "anims": {"idle": ["censor_base"]},
    },
    "penitent": {
        "height": 100,
        "anims": {"idle": ["penitent_base"]},
    },
    "oren": {
        "height": 76,
        "anims": {"idle": ["oren_base"]},
    },
    "null_children": {
        "height": 56,
        "anims": {"idle": ["nullchild_base"]},
    },
}

PROPS = {
    "door": ("prop_door", 210, 30),
    "anchor": ("prop_anchor", 110, 30),
    "terminal": ("prop_terminal", 120, 30),
}

FONTS = os.path.join(ROOT, "art", "fonts", "plexmono-regular.ttf")

def build_qa_sheet(groups, out_path):
    cells = []
    for label, frames in groups:
        for i, f in frames:
            cells.append((f"{label}_{i}", f))
    if not cells:
        return
    cell_w = max(f.size[0] for _, f in cells) + 16
    cell_h = max(f.size[1] for _, f in cells) + 34
    cols = min(6, len(cells))
    rows = (len(cells) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * cell_w, rows * cell_h), (20, 20, 22))
    d = ImageDraw.Draw(sheet)
    try:
        font = ImageFont.truetype(FONTS, 11)
    except Exception:
        font = ImageFont.load_default()
    for i, (label, f) in enumerate(cells):
        cx, cy = (i % cols) * cell_w, (i // cols) * cell_h
        d.rectangle([cx + 2, cy + 2, cx + cell_w - 3, cy + cell_h - 3], outline=(42, 42, 46))
        sheet.paste(f, (cx + (cell_w - f.size[0]) // 2,
                        cy + 24 + max(0, (cell_h - 34 - f.size[1]) // 2)), f)
        d.text((cx + 8, cy + 6), label, fill=(160, 152, 130), font=font)
    sheet.save(out_path)
    print("  QA sheet:", os.path.relpath(out_path, ROOT))

def main():
    only = sys.argv[1] if len(sys.argv) > 1 else None
    for char, spec in CHARACTERS.items():
        if only and only not in (char, "all"):
            continue
        outdir = os.path.join(ROOT, "art", "characters", char)
        os.makedirs(outdir, exist_ok=True)
        print(f"[{char}]")
        qa_groups = []
        missing = []
        for anim, raws in spec["anims"].items():
            frames = []
            g = spec.get("grade", {})
            for raw_name in raws:
                p = os.path.join(RAW, raw_name + ".png")
                if not os.path.isfile(p):
                    missing.append(raw_name)
                    continue
                f = process_frame(p, spec["height"],
                                  brighten=float(g.get("brighten", 1.06)),
                                  contrast=float(g.get("contrast", 1.06)))
                if f is not None:
                    frames.append(f)
            if not frames:
                continue
            frames, _ = compose_set(frames)
            for i, f in enumerate(frames):
                f.save(os.path.join(outdir, f"{anim}_{i}.png"))
            qa_groups.append((anim, list(enumerate(frames))))
        if qa_groups:
            build_qa_sheet(qa_groups, os.path.join(RAW, f"qa_{char}.png"))
        if missing:
            print("  missing raws:", ", ".join(sorted(set(missing))))
        expected = set()
        for anim, raws in spec["anims"].items():
            for i in range(len(raws)):
                expected.add(f"{anim}_{i}.png")
        for fn in os.listdir(outdir):
            if fn.endswith(".png") and fn not in expected:
                os.remove(os.path.join(outdir, fn))
                print("  removed stale:", fn)

    if not only or only in ("props", "all"):
        print("[props]")
        propdir = os.path.join(ROOT, "art", "props")
        os.makedirs(propdir, exist_ok=True)
        qa_groups = []
        for prop, (raw_name, h, th) in PROPS.items():
            p = os.path.join(RAW, raw_name + ".png")
            if not os.path.isfile(p):
                print("  missing raw:", raw_name)
                continue
            f = process_frame(p, h, thresh=th)
            if f is not None:
                f.save(os.path.join(propdir, prop + ".png"))
                qa_groups.append((prop, [(0, f)]))
        if qa_groups:
            build_qa_sheet(qa_groups, os.path.join(RAW, "qa_props.png"))

    if not only or only in ("env", "all"):
        print("[environment textures]")
        envdir = os.path.join(ROOT, "art", "environments")
        os.makedirs(envdir, exist_ok=True)
        for tex, size in (("tex_stone", 512), ("tex_metal", 512)):
            p = os.path.join(RAW, tex + ".png")
            if not os.path.isfile(p):
                print("  missing raw:", tex)
                continue
            img = Image.open(p).convert("RGB")
            img = img.resize((size, size), Image.LANCZOS)
            img = ImageEnhance.Color(img).enhance(0.82)
            img = ImageEnhance.Contrast(img).enhance(1.05)
            img = quantize_rgba(img)
            img.save(os.path.join(envdir, tex + ".png"))
            print("  wrote", tex + ".png")
    print("PIPELINE DONE")

if __name__ == "__main__":
    main()
