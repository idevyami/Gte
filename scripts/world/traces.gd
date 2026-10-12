## Traces — THE VESSEL'S TRACE (WB-14). The world's memory of the passage:
## footprints in the district's own floor material (dark compressions in the
## ash quarter, wet prints that DRY on the undercity stone, pressed nap on
## the chapel runner, fine dust in the archive), landing scuff-stars where
## the body met the ground hard, and roll smears. Bounded ring buffer,
## deterministic seeding per print, weathering per material.
## THE ONE DISTRICT THAT RECORDS NOTHING: the Engine's floor is maintained
## clean — it does not need to count; the census already owns the count.
## Painted ON the walking surface (above FloorCraft, below every light,
## decor and actor) so the prints sit IN the world, never on the lens.
class_name Traces
extends Node2D

const CAP := 96                    # the ring's bound — a path, not a ledger

# per-material recipes: born alpha, life (s), fade-start fraction, dry floor
# (wet prints dry toward a faint damp shadow before they leave), lighten
# (carpet: pressed nap reads LIGHTER, not darker), toe-kick crescent (ash
# piles where the boot pushed it).
# THE VISIBILITY LAW (learned the hard way, as WB-8 learned it): a dark
# mark on a charcoal floor is INVISIBLE. Every print is therefore TWO
# marks — the dark impression PLUS a bright rim of the material the boot
# DISPLACED. The rim alphas ride the same recipe.
const RECIPES := {
        "ash":    {"alpha": 0.62, "rim": 0.62, "life": 26.0, "fade": 0.62, "dry": -1.0, "lighten": false, "kick": true},
        "dust":   {"alpha": 0.50, "rim": 0.48, "life": 15.0, "fade": 0.45, "dry": -1.0, "lighten": false, "kick": false},
        "wet":    {"alpha": 0.66, "rim": 0.55, "life": 15.0, "fade": 0.85, "dry": 0.55, "lighten": false, "kick": false},
        "carpet": {"alpha": 0.50, "rim": 0.45, "life": 9.0,  "fade": 0.0,  "dry": -1.0, "lighten": true,  "kick": false},
}

const SMEAR_LIFE := 6.0            # roll marks weather faster than prints
const SMEAR_ALPHA := 0.42

var material_name := "none"
var _prints: Array = []            # the ring {kind, x, y, side, rot, w, h, age, ...}
var _side := 0                     # last foot that landed (0 left, 1 right)
var _t := 0.0
var _redraw_t := 0.0
var _rng := RandomNumberGenerator.new()

func setup(p_key: String, p_material: String) -> void:
        material_name = p_material
        _prints.clear()
        _side = 0
        _rng.seed = hash("traces:" + p_key)
        z_index = 0
        set_process(true)
        queue_redraw()

# ------------------------------------------------------------------ stamps

func stamp_foot(pos: Vector2, dir: float, p_strength := 1.0) -> void:
        ## One stride's impression. The side alternates; the print staggers
        ## along the path (front/back foot) and a hair in depth; the boot
        ## rotates into the direction of travel.
        if material_name == "none" or not RECIPES.has(material_name):
                return
        var rec: Dictionary = RECIPES[material_name]
        _side = 1 - _side
        var stag := (1.0 if _side == 1 else -1.0)
        var w := 9.0 * (0.9 + 0.2 * p_strength)
        var h := 16.5 * (0.9 + 0.2 * p_strength)
        _prints.append({
                "kind": "foot",
                "x": pos.x + stag * _rng.randf_range(2.6, 4.4),
                "y": pos.y + stag * _rng.randf_range(0.8, 1.8),
                "side": _side,
                "rot": dir * _rng.randf_range(0.04, 0.11) + stag * 0.03,
                "w": w, "h": h,
                "age": 0.0,
                "life": float(rec["life"]),
                "born": float(rec["alpha"]) * (0.9 + 0.2 * p_strength),
                "rim": float(rec["rim"]) * (0.9 + 0.2 * p_strength),
                "fade": float(rec["fade"]),
                "dry": float(rec["dry"]),
                "lighten": bool(rec["lighten"]),
                "kick": bool(rec["kick"]) and _side == 1,
                "kick_dir": dir,
        })
        _trim()

func stamp_land(pos: Vector2, strength: float) -> void:
        ## A hard landing: both soles together and a scuff-star of thrown
        ## material radiating from the impact — bigger the harder the fall.
        if material_name == "none" or not RECIPES.has(material_name):
                return
        var rec: Dictionary = RECIPES[material_name]
        var arms := 4 + int(3.0 * strength)
        _prints.append({
                "kind": "land",
                "x": pos.x, "y": pos.y,
                "rot": 0.0,
                "w": (9.0 + 9.0 * strength), "h": (13.0 + 6.0 * strength),
                "age": 0.0,
                "life": float(rec["life"]) * 1.15,
                "born": float(rec["alpha"]) * (1.0 + 0.5 * strength),
                "rim": float(rec["rim"]) * (1.0 + 0.5 * strength),
                "fade": float(rec["fade"]),
                "dry": float(rec["dry"]),
                "lighten": false,
                "kick": false,
                "star": arms,
                "star_r": (26.0 + 40.0 * strength),
                "seed": _rng.randf() * TAU,
        })
        _trim()

func stamp_roll(pos: Vector2, dir: float) -> void:
        ## The roll drags: a short smear where the body ground across the
        ## surface. Weathered faster than any print.
        if material_name == "none" or not RECIPES.has(material_name):
                return
        _prints.append({
                "kind": "smear",
                "x": pos.x, "y": pos.y,
                "rot": 0.0,
                "w": _rng.randf_range(18.0, 26.0), "h": 5.0,
                "age": 0.0,
                "life": SMEAR_LIFE,
                "born": SMEAR_ALPHA,
                "rim": SMEAR_ALPHA * 0.75,
                "fade": 0.5,
                "dry": -1.0,
                "lighten": false,
                "kick": false,
                "kick_dir": dir,
                "seed": _rng.randf() * TAU,
        })
        _trim()

func stamp_roll_path(x0: float, x1: float, y: float, dir: float) -> void:
        ## THE CONTINUOUS DRAG: the roll's own dash-marks (one per puff)
        ## plus this ONE LONG STREAK spanning the whole path — four dashes
        ## in a busy floor read as debris; one long drag reads as a body
        ## ground across the stone.
        if material_name == "none" or not RECIPES.has(material_name):
                return
        if absf(x1 - x0) < 24.0:
                return
        _prints.append({
                "kind": "smear",
                "x": (x0 + x1) * 0.5, "y": y,
                "rot": 0.0,
                "w": absf(x1 - x0) + 18.0, "h": 5.0,
                "age": 0.0,
                "life": SMEAR_LIFE * 1.3,
                "born": SMEAR_ALPHA * 1.15,
                "rim": SMEAR_ALPHA * 0.9,
                "fade": 0.5,
                "dry": -1.0,
                "lighten": false,
                "kick": false,
                "kick_dir": dir,
                "seed": _rng.randf() * TAU,
        })
        _trim()

func _trim() -> void:
        while _prints.size() > CAP:
                _prints.pop_front()

# ------------------------------------------------------------------ weather

func _process(delta: float) -> void:
        if _prints.is_empty():
                return
        _t += delta
        for p in _prints:
                p["age"] = float(p["age"]) + delta
        _prints = _prints.filter(func(p): return float(p["age"]) < float(p["life"]))
        # thrift cadence: the ring redraws at ~12Hz — births read instantly
        # to the eye, and 96 soft shapes cost nothing
        _redraw_t += delta
        if _redraw_t >= 0.08:
                _redraw_t = 0.0
                queue_redraw()

func simulate(delta: float) -> void:
        ## Test/proof hook: weather the ring without the tree's clock.
        _process(delta)

func alpha_factor(p: Dictionary) -> float:
        ## How present a print still is: the born alpha scaled by the
        ## material's weathering curve (wet DRIES toward a faint damp
        ## shadow, carpet recovers continuously, ash holds then leaves).
        var age := float(p["age"])
        var life := float(p["life"])
        var fade := float(p["fade"])
        var dry := float(p["dry"])
        var f := 1.0
        if dry > 0.0:
                # wet: dries to 0.18 of self by `dry` fraction, holds, then leaves
                if age <= life * dry:
                        f = 1.0 - 0.82 * smoothstep(0.0, life * dry, age)
                else:
                        f = 0.18 * (1.0 - smoothstep(life * dry, life, age))
        elif fade <= 0.0:
                # carpet: continuous recovery of the pressed nap
                f = 1.0 - smoothstep(0.0, life, age)
        else:
                if age > life * fade:
                        f = 1.0 - smoothstep(life * fade, life, age)
        return f

# ------------------------------------------------------------------ queries

func count() -> int:
        return _prints.size()

func count_kind(kind: String) -> int:
        var n := 0
        for p in _prints:
                if String(p["kind"]) == kind:
                        n += 1
        return n

func print_at(i: int) -> Dictionary:
        return _prints[i]

func has_glisten(p: Dictionary) -> bool:
        ## A wet print glistens while it is still wet (the first quarter of
        ## its life) — the leading edge catches what light there is.
        return float(p["dry"]) > 0.0 and float(p["age"]) < float(p["life"]) * 0.25

# ------------------------------------------------------------------ render

func _draw() -> void:
        if material_name == "none":
                return
        for p in _prints:
                var f := alpha_factor(p)
                var a := f * float(p["born"])
                var ra := f * float(p.get("rim", 0.0))
                if a <= 0.01 and ra <= 0.01:
                        continue
                var kind := String(p["kind"])
                if kind == "foot":
                        _draw_foot(p, a, ra)
                elif kind == "land":
                        _draw_land(p, a, ra)
                else:
                        _draw_smear(p, a, ra)

func _draw_foot(p: Dictionary, a: float, ra: float) -> void:
        var pos := Vector2(float(p["x"]), float(p["y"]))
        var rot := float(p["rot"])
        var w := float(p["w"])
        var h := float(p["h"])
        var light := bool(p["lighten"])
        # THE VISIBILITY LAW: every print is TWO marks. On dark floors the
        # boot leaves a dark impression wrapped in a BRIGHT rim of the
        # material it displaced; on the chapel's runner the pressed nap
        # reads LIGHTER with a dark shadow edge beneath it. The runner's
        # mark stays MATTE — soft stacked ellipses with the nap's grain,
        # never a glossy fill.
        var core: Color
        var rim: Color
        if light:
                core = Color(E0.PARCH.r * 1.06, E0.PARCH.g * 1.04, E0.PARCH.b, a * 0.62)
                rim = Color(0.10, 0.05, 0.06, ra)
        else:
                core = Color(0.07, 0.06, 0.07, a)
                rim = Color(E0.PARCH.r * 1.12, E0.PARCH.g * 1.10, E0.PARCH.b * 1.04, ra)
        draw_set_transform(pos, rot, Vector2.ONE)
        if light:
                # the runner: a MATTE flattened nap — stacked soft passes +
                # the grain's darker striations, never a specular fill
                _soft_ellipse(Vector2.ZERO, w * 0.72, h * 0.38, core, a * 0.7)
                _soft_ellipse(Vector2(0.0, h * 0.19), w * 0.5, h * 0.22, core, a * 0.55)
                for gr in 3:
                        draw_line(Vector2(-w * 0.4, -h * 0.12 + float(gr) * 2.6),
                                Vector2(w * 0.34, -h * 0.12 + float(gr) * 2.6),
                                Color(0.16, 0.07, 0.08, ra * 0.8), 1.0)
        else:
                # the displaced-material rim first — a slightly larger sole the dark
                # impression sits inside, so the print reads on ANY floor value
                _sole_local(w * 1.42, h * 1.24, rim)
                _sole_local(w, h, core)
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
        if bool(p["kick"]):
                # ash piles at the toe of the trailing boot — the material
                # the body pushed (world space)
                var kd := float(p["kick_dir"])
                var kx := pos.x + kd * (h * 0.45)
                var kc := Color(E0.PARCH.r * 1.15, E0.PARCH.g * 1.12, E0.PARCH.b * 1.05, ra * 1.25)
                draw_circle(Vector2(kx, pos.y + 1.0), 3.4, kc)
                draw_circle(Vector2(kx + kd * 3.4, pos.y + 0.4), 2.2, kc)
                draw_circle(Vector2(kx + kd * 6.0, pos.y - 0.2), 1.4, kc)
        if has_glisten(p):
                # the wet edge catches the light while it is still wet — a
                # bright double-L wrapping the toe and the ball's leading
                # side (the sharpest read of DAMP in the dark)
                var ge := Color(E0.BONE.r * 1.3, E0.BONE.g * 1.26, E0.BONE.b * 1.08, clampf(a * 0.95, 0.0, 0.92))
                var ge2 := Color(E0.BONE.r * 1.15, E0.BONE.g * 1.12, E0.BONE.b, clampf(a * 0.5, 0.0, 0.5))
                var toe_l := pos + Vector2(-w * 0.7, -h * 0.62).rotated(rot)
                var toe_r := pos + Vector2(w * 0.7, -h * 0.62).rotated(rot)
                var side_b := pos + Vector2(w * 0.7, -h * 0.1).rotated(rot)
                draw_polyline(PackedVector2Array([toe_l, toe_r, side_b]), ge, 3.0)
                draw_polyline(PackedVector2Array([
                        toe_l + Vector2(0, 2.4), toe_r + Vector2(0, 2.4), side_b + Vector2(0, 2.4)]), ge2, 1.6)

func _sole_local(w: float, h: float, ink: Color) -> void:
        ## Ball of the foot + heel as ROUNDED masses (capsules — a boot's
        ## impression is organic, never a rectangle). LOCAL space: the
        ## caller owns the transform.
        _capsule_local(w, h * 0.62, ink, 0.0, -h * 0.19)          # the ball
        _capsule_local(w * 0.64, h * 0.34, ink, 0.0, h * 0.33)    # the heel

func _capsule_local(w: float, h: float, ink: Color, ox := 0.0, oy := 0.0) -> void:
        ## A rounded capsule centered at (ox, oy): body rect + two end
        ## caps — reads organic at any zoom. The caps stay under a third
        ## of the height so the mass keeps its oblong boot read.
        var r := minf(w * 0.5, h * 0.32)
        var x0 := ox - w * 0.5
        var y0 := oy - h * 0.5 + r
        var y1 := oy + h * 0.5 - r
        if y1 <= y0:
                draw_circle(Vector2(ox, oy), minf(w, h) * 0.5, ink)
                return
        draw_rect(Rect2(x0, y0, w, y1 - y0), ink)
        draw_circle(Vector2(ox, y0), r, ink)
        draw_circle(Vector2(ox, y1), r, ink)

func _draw_land(p: Dictionary, a: float, ra: float) -> void:
        var pos := Vector2(float(p["x"]), float(p["y"]))
        var core := Color(0.07, 0.06, 0.07, a)
        var rim := Color(E0.PARCH.r * 1.12, E0.PARCH.g * 1.10, E0.PARCH.b * 1.04, ra)
        var w := float(p["w"])
        var h := float(p["h"])
        # the impact bruise FIRST — a wide dark ellipse the soles press INTO
        var bruise := Color(0.05, 0.05, 0.06, a * 0.55)
        var bpts := PackedVector2Array()
        for i in 12:
                var ba := TAU * i / 12.0
                bpts.append(pos + Vector2(cos(ba) * w * 0.78, sin(ba) * h * 0.4))
        draw_colored_polygon(bpts, bruise)
        # both soles together, a little splayed, each wrapped in its rim,
        # pressed INTO the bruise (never veiled by it)
        for side in [-1.0, 1.0]:
                draw_set_transform(pos + Vector2(side * w * 0.42, 0), side * 0.10, Vector2.ONE)
                _sole_local(w * 0.52 * 1.42, h * 1.24, rim)
                _sole_local(w * 0.52, h, core)
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
        # the scuff-star: material FLUNG from the impact — every flight is
        # organic chaos (bent trajectories, varied lengths and thickness,
        # alpha-faded ends, a stray fleck beside the main throw) — never
        # evenly-spaced straight lines with node dots (that reads as a
        # schematic, not a burst)
        var arms := int(p["star"])
        var r := float(p["star_r"])
        var seed_a := float(p["seed"])
        var thrown := Color(E0.PARCH.r * 1.18, E0.PARCH.g * 1.15, E0.PARCH.b * 1.06, clampf(ra * 1.5, 0.0, 0.95))
        var clod := Color(0.07, 0.06, 0.07, a * 0.85)
        for i in arms:
                var h1 := fmod(sin(seed_a * 101.0 + float(i) * 17.3) * 43758.5453, 1.0)
                var h2 := fmod(sin(seed_a * 59.0 + float(i) * 7.7) * 22578.145, 1.0)
                var h3 := fmod(sin(seed_a * 31.0 + float(i) * 3.1) * 9821.777, 1.0)
                var ang := seed_a + TAU * (float(i) + 0.5 * (h1 - 0.5)) / float(arms)
                var dir2 := Vector2(cos(ang), sin(ang) * 0.55)
                var len := r * (0.55 + 0.45 * h2)
                # the main flight: two segments with a bend — a clod arcing
                # out, thinning and fading as it loses its violence
                var bend := dir2.rotated(signf(h3 - 0.5) * (0.35 + 0.4 * h3))
                var p0 := pos + dir2 * r * 0.12
                var pm := pos + dir2 * len * 0.55 + bend * len * 0.10
                var pt := pos + dir2 * len + bend * len * 0.06
                draw_line(p0, pm, clod, 2.8 - 0.8 * h2)
                draw_line(pm, pt, Color(clod.r, clod.g, clod.b, clod.a * 0.55), 1.4)
                # the dust that lifts off the flight — above it, fainter
                draw_line(p0 + Vector2(0, -1.5), pm + Vector2(0, -1.5),
                        Color(thrown.r, thrown.g, thrown.b, thrown.a * 0.6), 1.2)
                # the fading puff where the clod lands (no hard node)
                draw_circle(pt, 1.9, Color(thrown.r, thrown.g, thrown.b, thrown.a * 0.55))
                draw_circle(pt, 1.1, Color(thrown.r, thrown.g, thrown.b, thrown.a * 0.3))
                # the stray fleck — a second, shorter throw beside the main
                if h1 > 0.4:
                        var fdir := dir2.rotated(signf(h2 - 0.5) * (0.3 + 0.3 * h2))
                        var fp := pos + fdir * len * (0.4 + 0.3 * h3)
                        draw_line(pos + dir2 * r * 0.1, fp,
                                Color(clod.r, clod.g, clod.b, clod.a * 0.7), 1.3)
                        draw_circle(fp, 1.2, Color(thrown.r, thrown.g, thrown.b, thrown.a * 0.4))

func _draw_smear(p: Dictionary, a: float, ra: float) -> void:
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
        var pos := Vector2(float(p["x"]), float(p["y"]))
        var w := float(p["w"])
        var seedv := float(p.get("seed", 0.37))
        var rim := Color(E0.PARCH.r * 1.12, E0.PARCH.g * 1.09, E0.PARCH.b * 1.04, ra)
        var core := Color(0.07, 0.06, 0.07, a)
        var kd := float(p["kick_dir"])
        var x0 := pos.x - w * 0.5
        # A ROLL IS REPEATED BODY-TO-GROUND CONTACTS: a faint irregular wash
        # along the path, pressed soft blotches where the body met the
        # floor (irregular spacing and size — never a chain of links),
        # dashed grind lines, and a kicked-up pile where the grind began
        # --- the wash: one irregular smudge silhouette under everything
        var wash := PackedVector2Array()
        var wbot := PackedVector2Array()
        var xw := x0
        while xw <= x0 + w:
                var tw := (xw - x0) / maxf(w, 1.0)
                var hh := (2.0 + 2.2 * absf(sin(seedv * 17.0 + tw * 9.3))) \
                        * (1.0 - 0.5 * (tw if kd > 0 else 1.0 - tw))
                wash.append(Vector2(xw, pos.y - hh + sin(seedv * 41.0 + tw * 15.0) * 1.1))
                wbot.append(Vector2(xw, pos.y + hh * 0.75))
                xw += 5.0 + fmod(xw * 1.31 + seedv * 29.0, 6.0)
        wbot.reverse()
        wash.append_array(wbot)
        draw_colored_polygon(wash, Color(rim.r, rim.g, rim.b, ra * 0.5))
        # --- the pressed blotches: where the body's shoulder and back
        #     ground into the material — soft, stacked, IRREGULAR (size and
        #     pressure lurch as the body tumbles; the contact point wanders
        #     up and down the path's width)
        var nb := maxi(3, int(w / 30.0))
        for i in nb:
                var tb := (float(i) + 0.5) / float(nb)
                var hsh := fmod(seedv * 977.0 + float(i) * 131.0, 1.0)
                var tbx := x0 + w * tb + (hsh - 0.5) * 14.0
                var tby := pos.y + (fmod(seedv * 337.0 + float(i) * 71.0, 1.0) - 0.5) * 6.0
                var brx := (4.0 + 6.5 * fmod(seedv * 173.0 + float(i) * 47.0, 1.0)) \
                        * (1.0 - 0.45 * (tb if kd > 0 else 1.0 - tb))
                var bry := brx * (0.42 + 0.25 * fmod(seedv * 519.0 + float(i) * 13.0, 1.0))
                var pressure := 0.5 + 0.5 * fmod(seedv * 761.0 + float(i) * 29.0, 1.0)
                _soft_ellipse(Vector2(tbx, tby), brx, bry, rim, ra * (0.55 + 0.45 * pressure))
                # the dark press inside — the body's weight, heavier on the
                # hard contacts, absent on the light ones
                if pressure > 0.42:
                        _soft_ellipse(Vector2(tbx + kd * 1.5, tby), brx * 0.48, bry * 0.48,
                                core, a * (0.5 + 0.5 * pressure))
        # --- hashed grind dashes: stuttering, chaotic abrasion trails
        var di := 0
        var dx := x0 + 3.0
        while dx < x0 + w - 5.0:
                var h2 := fmod(sin(seedv * 101.0 + float(di) * 17.3) * 43758.5453, 1.0)
                var h3 := fmod(sin(seedv * 59.0 + float(di) * 7.7) * 22578.145, 1.0)
                var dash := 3.5 + 8.5 * absf(h2)
                var lane := 1 if h3 < 0.5 else 0
                var yy := pos.y - 1.0 + float(lane) * 2.2 + (h3 - 0.5) * 1.6
                draw_line(Vector2(dx, yy), Vector2(minf(dx + dash, x0 + w - 4.0), yy),
                        Color(core.r, core.g, core.b, a * (0.55 + 0.4 * absf(h2))), 1.5)
                dx += dash + 3.0 + 6.0 * absf(h3)
                di += 1
        # --- the kicked-up pile where the grind began (the tail)
        var tail := Vector2(x0 if kd > 0 else x0 + w, pos.y)
        var kc := Color(E0.PARCH.r * 1.16, E0.PARCH.g * 1.13, E0.PARCH.b * 1.05, clampf(ra * 1.25, 0.0, 0.95))
        draw_circle(tail + Vector2(kd * 1.0, -1.0), 3.4, kc)
        draw_circle(tail + Vector2(kd * 3.8, -2.8), 2.3, kc)
        draw_circle(tail + Vector2(kd * 6.4, -3.8), 1.5, kc)

func _soft_ellipse(c: Vector2, rx: float, ry: float, col: Color, alpha: float) -> void:
        ## A soft-edged ellipse: three stacked polygons, each smaller and
        ## more present than the last — a pressed smudge, not a shape.
        for layer in 3:
                var g := 1.5 - 0.25 * float(layer)
                var aa := alpha * (0.35 + 0.325 * float(layer))
                var pts := PackedVector2Array()
                for i in 10:
                        var ang := TAU * i / 10.0
                        pts.append(c + Vector2(cos(ang) * rx * g, sin(ang) * ry * g))
                draw_colored_polygon(pts, Color(col.r, col.g, col.b, aa))
