## Foreground — THE CLOSEST WALLS. The missing front slice of the depth
## sandwich: near-camera silhouettes (chains, cables, ragged banners, broken
## stumps, rubble, falling pages) that pass IN FRONT of the actors at 1.28x
## camera speed. The room finally has a front face, and it is nearer than
## the player — every sideways step slides the world past something.
##
## COMBAT CLARITY IS SACRED (the WB-4 law): nothing ever crosses the
## telegraph band. Hangs stop a full head-room above the tallest enemy
## telegraph ring; stumps stay strictly below the feet line; the vertical
## climb room (act1) caps hang length above its top platform. Interactive
## x-zones (doors, anchors, spawn, the boss arena) are kept clear in the
## foreground's own scrolled space: an element at virtual X occludes world
## x D when |X - 1.28*D| is small, so exclusion bands are placed at D*1.28.
##
## Everything is deterministic per room (seeded), silhouette-dark with a
## faint parchment rim (the world's light catching the nearest edge), and
## animated: chains sway, cables breathe their sag, rags flutter, shingles
## creak, pages fall.
class_name Foreground
extends Node2D

const SCROLL_K := 1.28          # horizontal: nearer than the gameplay plane
const SCROLL_KY := 1.06         # vertical: a whisper of near-shift
const RIM := Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.13)
const SILHOUETTE := Color(0.045, 0.045, 0.055, 0.97)

# per-district recipes: element kind weights (what the closest walls are
# made of where you stand)
const RECIPES := {
        "vessels": {"hang_cable": 3.0, "hang_chain": 2.0, "hang_shroud": 2.0, "stump_rubble": 2.0},
        "undercity": {"hang_chain": 2.5, "hang_lamp": 1.5, "hang_rag": 1.5, "stump_grate": 2.0, "stump_rubble": 1.5},
        "city": {"hang_sign": 2.5, "hang_rag": 2.0, "hang_lamp": 1.0, "stump_rubble": 2.0},
        "chapel": {"hang_censer": 2.5, "hang_rag": 2.0, "stump_column": 2.0, "stump_rubble": 1.0},
        "archive": {"hang_page": 3.0, "hang_chain": 1.0, "stump_shelf": 2.5, "stump_rubble": 1.0},
        "engine": {"hang_cable": 3.0, "hang_chain": 1.5, "stump_gantry": 2.5, "stump_rubble": 1.5},
        "reliquary": {"hang_censer": 2.0, "stump_column": 2.0, "hang_chain": 1.5},
        "aftermath": {"hang_rag": 3.0, "stump_rubble": 3.0, "stump_column": 1.0},
}

var room_id := ""
var backdrop_key := ""
var _room_w := 1280.0
var _room_h := 720.0
var _floor_y := 660.0
var _camera: Camera2D
var _elements: Array = []        # {kind, x(virtual), seed, len/w, ph, ...}
var _exclusions: Array = []      # {x (world), pad} — kept clear at D*1.28
var _t := 0.0
var _pages: Array = []           # falling page curtain motes (archive)
var _boss_room := false

func setup(p_room_id: String, p_backdrop: String, p_room_size: Vector2, p_floor_y: float,
                p_camera: Camera2D, p_exclusions: Array) -> void:
        room_id = p_room_id
        backdrop_key = p_backdrop
        _room_w = p_room_size.x
        _room_h = p_room_size.y
        _floor_y = p_floor_y if p_floor_y > 0.0 else p_room_size.y * 0.9
        _camera = p_camera
        _exclusions = p_exclusions
        _boss_room = p_room_id == "act8"
        z_index = 30
        _generate()
        _seed_pages()
        queue_redraw()

func element_count() -> int:
        return _elements.size()

func exclusion_count() -> int:
        return _exclusions.size()

func _in_exclusion(vx: float, half_w: float) -> bool:
        for ex in _exclusions:
                var center: float = float(ex["x"]) * SCROLL_K
                var pad: float = float(ex["pad"])
                if absf(vx - center) < pad + half_w:
                        return true
        return false

func _generate() -> void:
        _elements.clear()
        var recipe: Dictionary = RECIPES.get(backdrop_key, RECIPES["undercity"])
        var rng := RandomNumberGenerator.new()
        rng.seed = hash(room_id + ":FG")
        var band := _room_w * SCROLL_K
        # density: one near-object per ~500px of travel, clamped — sparse
        # reads as depth, dense reads as an obstruction
        var target := clampi(int(band / 500.0), 3, 7)
        # the vertical climb room trusts nothing that hangs — fewer, shorter
        if room_id == "act1":
                target = clampi(target - 1, 2, 4)
        var kinds: Array = recipe.keys()
        var total_w := 0.0
        for k in kinds:
                total_w += float(recipe[k])
        var last_x := -9999.0
        var attempts := 0
        while _elements.size() < target and attempts < 220:
                attempts += 1
                # weighted kind pick
                var pick := rng.randf() * total_w
                var kind: String = kinds[0]
                for k in kinds:
                        pick -= float(recipe[k])
                        if pick <= 0.0:
                                kind = String(k)
                                break
                var is_stump := kind.begins_with("stump_")
                var half_w := 34.0
                if kind == "hang_page" or kind == "hang_cable":
                        half_w = 70.0
                elif kind == "stump_column" or kind == "stump_shelf" or kind == "stump_gantry":
                        half_w = 30.0
                elif kind == "stump_grate":
                        half_w = 42.0
                var vx := rng.randf_range(-120.0, band + 120.0)
                # spacing: near objects never crowd — one at a time passes
                if absf(vx - last_x) < 340.0:
                        continue
                if _in_exclusion(vx, half_w):
                        continue
                var e := {
                        "kind": kind, "x": vx, "seed": rng.randf(),
                        "ph": rng.randf() * TAU, "w": 0.0, "len": 0.0,
                }
                # --- length law (the combat-clarity contract) ---
                var max_len := 400.0
                if room_id == "act1":
                        # the climb: hangs live in the sky band above the
                        # top platform (y 250) — never across the ascent
                        max_len = 230.0
                elif _boss_room:
                        # the martyr's arena: generous sky, nothing lower
                        max_len = 300.0
                match kind:
                        "hang_chain":
                                e["len"] = rng.randf_range(180.0, max_len)
                                e["w"] = rng.randf_range(10.0, 16.0)
                        "hang_cable":
                                e["len"] = rng.randf_range(60.0, 90.0)    # sag depth
                                e["w"] = rng.randf_range(240.0, 420.0)    # run width
                        "hang_rag":
                                e["len"] = rng.randf_range(140.0, minf(max_len, 300.0))
                                e["w"] = rng.randf_range(46.0, 78.0)
                        "hang_shroud":
                                e["len"] = rng.randf_range(160.0, minf(max_len, 290.0))
                                e["w"] = rng.randf_range(60.0, 96.0)
                        "hang_sign":
                                e["len"] = rng.randf_range(90.0, 150.0)   # rope length
                                e["w"] = rng.randf_range(52.0, 76.0)      # board width
                        "hang_lamp":
                                e["len"] = rng.randf_range(130.0, minf(max_len, 240.0))
                                e["w"] = 16.0
                        "hang_censer":
                                e["len"] = rng.randf_range(150.0, minf(max_len, 280.0))
                                e["w"] = 22.0
                        "hang_page":
                                e["len"] = rng.randf_range(220.0, 330.0)
                                e["w"] = rng.randf_range(120.0, 190.0)
                        "stump_column":
                                e["len"] = clampf((_room_h - _floor_y) * 0.6, 40.0, 250.0)
                                e["w"] = rng.randf_range(40.0, 58.0)
                        "stump_rubble":
                                e["len"] = clampf((_room_h - _floor_y) * 0.42, 30.0, 170.0)
                                e["w"] = rng.randf_range(80.0, 150.0)
                        "stump_grate":
                                e["len"] = clampf((_room_h - _floor_y) * 0.55, 36.0, 230.0)
                                e["w"] = rng.randf_range(60.0, 84.0)
                        "stump_shelf":
                                e["len"] = clampf((_room_h - _floor_y) * 0.5, 34.0, 210.0)
                                e["w"] = rng.randf_range(34.0, 50.0)
                        "stump_gantry":
                                e["len"] = clampf((_room_h - _floor_y) * 0.5, 34.0, 210.0)
                                e["w"] = rng.randf_range(38.0, 54.0)
                if is_stump:
                        # stumps never rise above the feet line
                        e["len"] = minf(e["len"], _room_h - _floor_y - 8.0)
                _elements.append(e)
                last_x = vx

func _seed_pages() -> void:
        _pages.clear()
        var has_page := false
        for e in _elements:
                if e["kind"] == "hang_page":
                        has_page = true
                        break
        if not has_page:
                return
        var rng := RandomNumberGenerator.new()
        rng.seed = hash(room_id + ":FGP")
        for i in 10:
                _pages.append({
                        "e": -1, "ox": rng.randf_range(-70.0, 70.0),
                        "y": rng.randf_range(0.0, 1.0), "sp": rng.randf_range(0.045, 0.1),
                        "sw": rng.randf_range(8.0, 20.0), "ph": rng.randf() * TAU,
                        "s": rng.randf_range(0.7, 1.3),
                })

func _process(delta: float) -> void:
        _t += delta
        for p in _pages:
                p["y"] = fmod(float(p["y"]) + float(p["sp"]) * delta * 6.0, 1.0)
        queue_redraw()

func _draw() -> void:
        if not OS.get_environment("E0_NO_FOREGROUND").is_empty():
                return
        if _camera == null:
                return
        var cam := _camera.global_position
        for e in _elements:
                var kind: String = e["kind"]
                # near-plane slide: virtual x minus the extra scroll share
                var px: float = float(e["x"]) - cam.x * (SCROLL_K - 1.0)
                if kind.begins_with("hang_"):
                        _draw_hang(e, px, cam)
                else:
                        _draw_stump(e, px, cam)
        # falling pages ride their curtain anchors
        if not _pages.is_empty():
                var pi := 0
                for e in _elements:
                        if e["kind"] != "hang_page":
                                continue
                        var px: float = float(e["x"]) - cam.x * (SCROLL_K - 1.0)
                        var top_y := -30.0 - cam.y * (SCROLL_KY - 1.0)
                        var bot_y := top_y + float(e["len"])
                        var p: Dictionary = _pages[pi % _pages.size()]
                        pi += 1
                        var py := lerpf(top_y + 30.0, bot_y - 10.0, float(p["y"]))
                        var sway := sin(_t * 1.6 + float(p["ph"])) * float(p["sw"])
                        _page(Vector2(px + float(p["ox"]) + sway, py), float(p["s"]), float(p["ph"]))

# ------------------------------------------------------------------ helpers

func _ghost_rect(r: Rect2) -> void:
        ## cheap defocus: a soft offset halo under every solid edge — near
        ## objects carry their own blur
        draw_rect(r.grow(2.0).grow_individual(3.0, 0.0, 3.0, 0.0), Color(SILHOUETTE.r, SILHOUETTE.g, SILHOUETTE.b, 0.20))

func _rim_line(a: Vector2, b: Vector2) -> void:
        draw_line(a, b, RIM, 1.4)

func _draw_hang(e: Dictionary, px: float, cam: Vector2) -> void:
        var kind: String = e["kind"]
        var top_y := -34.0 - cam.y * (SCROLL_KY - 1.0)
        match kind:
                "hang_chain":
                        _chain(px, top_y, float(e["len"]), float(e["w"]), float(e["ph"]))
                "hang_cable":
                        _cable(px, top_y, float(e["w"]), float(e["len"]), float(e["ph"]))
                "hang_rag":
                        _rag(px, top_y, float(e["w"]), float(e["len"]), float(e["ph"]))
                "hang_shroud":
                        _shroud(px, top_y, float(e["w"]), float(e["len"]), float(e["ph"]))
                "hang_sign":
                        _sign(px, top_y, float(e["w"]), float(e["len"]), float(e["ph"]))
                "hang_lamp":
                        _lamp(px, top_y, float(e["len"]), float(e["ph"]))
                "hang_censer":
                        _censer(px, top_y, float(e["len"]), float(e["ph"]))
                "hang_page":
                        _page_curtain(px, top_y, float(e["w"]), float(e["len"]))

func _draw_stump(e: Dictionary, px: float, _cam: Vector2) -> void:
        var kind: String = e["kind"]
        var w := float(e["w"])
        var h := float(e["len"])
        var base_y := _floor_y + 16.0           # strictly below the feet line
        match kind:
                "stump_column":
                        _stump_column(px, base_y, w, h, float(e["ph"]))
                "stump_rubble":
                        _stump_rubble(px, base_y, w, h, float(e["seed"]))
                "stump_grate":
                        _stump_grate(px, base_y, w, h, float(e["ph"]))
                "stump_shelf":
                        _stump_shelf(px, base_y, w, h, float(e["seed"]))
                "stump_gantry":
                        _stump_gantry(px, base_y, w, h, float(e["ph"]))

# ------------------------------------------------------------------ hangs

func _chain(px: float, top_y: float, len: float, w: float, ph: float) -> void:
        ## near chains: fat links, heavy pendulum — mounted through a beam
        ## ring so they never float out of the void
        var links := maxi(3, int(len / 26.0))
        var link := len / float(links)
        var sway_t := sin(_t * 0.55 + ph)
        var x := px
        var y := top_y
        draw_rect(Rect2(px - w * 0.8, top_y - 8.0, w * 1.6, 9.0), SILHOUETTE)
        _rim_line(Vector2(px - w * 0.8, top_y - 8.0), Vector2(px + w * 0.8, top_y - 8.0))
        for i in links:
                var sway := sway_t * (3.0 + i * 0.85)
                var nx := px + sway
                var ny := y + link
                draw_line(Vector2(x, y + 3.0), Vector2(nx, ny - 3.0),
                        Color(SILHOUETTE.r, SILHOUETTE.g, SILHOUETTE.b, 0.92), w * 0.75)
                draw_arc(Vector2((x + nx) * 0.5, (y + ny) * 0.5), w * 0.62, 0, TAU, 8,
                        Color(SILHOUETTE.r, SILHOUETTE.g, SILHOUETTE.b, 0.85), w * 0.5)
                x = nx
                y = ny
        # hook end
        draw_arc(Vector2(x, y + 6.0), w * 0.8, PI * 0.2, PI * 1.1, 8, SILHOUETTE, w * 0.55)
        _rim_line(Vector2(x - w * 0.6, y), Vector2(x + w * 0.6, y))

func _cable(px: float, top_y: float, run_w: float, sag: float, ph: float) -> void:
        ## cable run: two mounts, a sagging span that BREATHES (the near
        ## wall's own slow pulse), hangers every so often
        var x0 := px - run_w * 0.5
        var x1 := px + run_w * 0.5
        var breathe := sin(_t * 0.45 + ph) * 9.0
        var s := sag + breathe
        draw_rect(Rect2(x0 - 5.0, top_y - 6.0, 10.0, 14.0), SILHOUETTE)
        draw_rect(Rect2(x1 - 5.0, top_y - 6.0, 10.0, 14.0), SILHOUETTE)
        var steps := 14
        var prev := Vector2(x0, top_y)
        for i in steps:
                var t := float(i + 1) / float(steps)
                var cx := lerpf(x0, x1, t)
                var cy := top_y + sin(t * PI) * s
                draw_line(prev, Vector2(cx, cy), Color(SILHOUETTE.r, SILHOUETTE.g, SILHOUETTE.b, 0.95), 5.0)
                prev = Vector2(cx, cy)
        _rim_line(Vector2(x0, top_y + 1.0), Vector2(x0 + run_w * 0.2, top_y + sin(0.2 * PI) * s))
        # drop hangers (short ties, not full wires — they must not dangle
        # into the telegraph band)
        for i in 3:
                var t := 0.25 + 0.25 * i
                var hx := lerpf(x0, x1, t)
                var hy := top_y + sin(t * PI) * s
                draw_line(Vector2(hx, hy), Vector2(hx, hy + 16.0), Color(SILHOUETTE.r, SILHOUETTE.g, SILHOUETTE.b, 0.85), 3.0)

func _rag(px: float, top_y: float, w: float, len: float, ph: float) -> void:
        ## torn banner: a rod, then hanging strips whose rows shear in a
        ## travelling flutter — cloth reacting to air you cannot see
        _ghost_rect(Rect2(px - w * 0.5, top_y, w, len))
        draw_rect(Rect2(px - w * 0.62, top_y - 5.0, w * 1.24, 6.0), SILHOUETTE)
        _rim_line(Vector2(px - w * 0.62, top_y - 5.0), Vector2(px + w * 0.62, top_y - 5.0))
        var cols := 4
        var rows := 9
        for c in cols:
                var cx := px - w * 0.5 + w * (float(c) + 0.5) / float(cols)
                var strip_w := w / float(cols) - 3.0
                # each strip torn to its own length
                var sl := len * (0.55 + 0.45 * absf(sin(ph + c * 2.1)))
                var prev := Vector2(cx, top_y)
                for r in rows:
                        var t := float(r + 1) / float(rows)
                        var shear := sin(_t * 2.6 + ph + t * 4.0 + c * 1.3) * (3.0 + t * 9.0)
                        var np := Vector2(cx + shear, top_y + sl * t)
                        draw_colored_polygon(PackedVector2Array([
                                prev + Vector2(-strip_w * 0.5, 0.0), prev + Vector2(strip_w * 0.5, 0.0),
                                np + Vector2(strip_w * 0.5, 0.0), np + Vector2(-strip_w * 0.5, 0.0),
                        ]), Color(SILHOUETTE.r, SILHOUETTE.g, SILHOUETTE.b, 0.94))
                        prev = np
                _rim_line(Vector2(cx - strip_w * 0.5, top_y), Vector2(cx - strip_w * 0.5, top_y + sl * 0.35))

func _shroud(px: float, top_y: float, w: float, len: float, ph: float) -> void:
        ## vessel shroud: a full cloth sheet with a sagging hem that sways
        ## — something soft hanging in the womb's foreground
        _ghost_rect(Rect2(px - w * 0.5, top_y, w, len))
        var hem := sin(_t * 0.7 + ph) * 7.0
        var pts := PackedVector2Array([
                Vector2(px - w * 0.5, top_y),
                Vector2(px + w * 0.5, top_y),
                Vector2(px + w * 0.42 + hem, top_y + len),
                Vector2(px + w * 0.1 + hem * 0.6, top_y + len - 14.0),
                Vector2(px - w * 0.25 + hem * 0.3, top_y + len + 8.0),
                Vector2(px - w * 0.46, top_y + len - 10.0),
        ])
        draw_colored_polygon(pts, Color(SILHOUETTE.r, SILHOUETTE.g, SILHOUETTE.b, 0.96))
        _rim_line(Vector2(px - w * 0.5, top_y), Vector2(px - w * 0.46, top_y + len * 0.7))
        # pin mounts
        for i in 3:
                var mx := px - w * 0.4 + w * 0.4 * i
                draw_circle(Vector2(mx, top_y + 2.0), 3.4, SILHOUETTE)

func _sign(px: float, top_y: float, w: float, rope: float, ph: float) -> void:
        ## creaking shingle: two ropes, a board that swings a few degrees
        ## and knocks — the city's closest shop, long dead
        var creak := sin(_t * 0.8 + ph) * 0.055
        var knock := absf(sin(_t * 0.8 + ph)) > 0.97
        if knock:
                creak *= 2.2
        var bx := px + sin(creak) * rope * 0.5
        var by := top_y + rope
        draw_line(Vector2(px - w * 0.3, top_y), Vector2(bx - w * 0.3, by), Color(SILHOUETTE.r, SILHOUETTE.g, SILHOUETTE.b, 0.9), 2.5)
        draw_line(Vector2(px + w * 0.3, top_y), Vector2(bx + w * 0.3, by), Color(SILHOUETTE.r, SILHOUETTE.g, SILHOUETTE.b, 0.9), 2.5)
        _ghost_rect(Rect2(bx - w * 0.5, by, w, w * 0.62))
        draw_rect(Rect2(bx - w * 0.5, by, w, w * 0.62), SILHOUETTE)
        _rim_line(Vector2(bx - w * 0.5, by), Vector2(bx - w * 0.5, by + w * 0.62))
        # the glyph long burned off — three pale scars
        for i in 3:
                draw_line(Vector2(bx - w * 0.22 + i * w * 0.2, by + w * 0.16),
                        Vector2(bx - w * 0.16 + i * w * 0.2, by + w * 0.44),
                        Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.10), 2.0)

func _lamp(px: float, top_y: float, len: float, ph: float) -> void:
        ## dead street lamp leaning into frame: bracket arm + hooded head,
        ## a faint cold ember still insisting on light
        var sway := sin(_t * 0.4 + ph) * 2.0
        draw_line(Vector2(px, top_y), Vector2(px + sway, top_y + len), Color(SILHOUETTE.r, SILHOUETTE.g, SILHOUETTE.b, 0.95), 6.0)
        var hx := px + sway
        var hy := top_y + len
        _ghost_rect(Rect2(hx - 16.0, hy, 32.0, 22.0))
        draw_colored_polygon(PackedVector2Array([
                Vector2(hx - 16.0, hy), Vector2(hx + 16.0, hy),
                Vector2(hx + 10.0, hy + 20.0), Vector2(hx - 10.0, hy + 20.0),
        ]), SILHOUETTE)
        _rim_line(Vector2(hx - 16.0, hy), Vector2(hx + 16.0, hy))
        var flick := 0.5 + 0.5 * sin(_t * 7.0 + ph * 3.0)
        draw_circle(Vector2(hx, hy + 12.0), 3.0, Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.10 + 0.08 * flick))

func _censer(px: float, top_y: float, len: float, ph: float) -> void:
        ## near censer on a swing: bigger than the chapel's mid-plane
        ## censers — this one is close enough to smell
        var swing := sin(_t * 0.9 + ph) * 0.14
        var ex := px + sin(swing) * len
        var ey := top_y + cos(swing) * len
        draw_line(Vector2(px, top_y), Vector2(ex, ey), Color(SILHOUETTE.r, SILHOUETTE.g, SILHOUETTE.b, 0.9), 3.0)
        _ghost_rect(Rect2(ex - 14.0, ey, 28.0, 18.0))
        draw_colored_polygon(PackedVector2Array([
                Vector2(ex - 14.0, ey), Vector2(ex + 14.0, ey),
                Vector2(ex + 9.0, ey + 16.0), Vector2(ex - 9.0, ey + 16.0),
        ]), SILHOUETTE)
        _rim_line(Vector2(ex - 14.0, ey), Vector2(ex + 14.0, ey))
        for i in 2:
                var t := fmod(_t * 0.3 + ph + i * 0.5, 1.0)
                draw_circle(Vector2(ex + sin(t * TAU) * 6.0, ey + 14.0 - t * 30.0), 2.6 - t * 1.6,
                        Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, (1.0 - t) * 0.16))

func _page_curtain(px: float, top_y: float, w: float, len: float) -> void:
        ## the archive's nearest shelf has burst: a curtain rail, a drift of
        ## falling pages caught mid-air — records dying in public
        draw_rect(Rect2(px - w * 0.55, top_y - 6.0, w * 1.1, 7.0), SILHOUETTE)
        _rim_line(Vector2(px - w * 0.55, top_y - 6.0), Vector2(px + w * 0.55, top_y - 6.0))
        # the fall field is drawn by _draw()'s page motes; here only a few
        # static clinging sheets
        for i in 3:
                var cx := px - w * 0.35 + w * 0.35 * i
                var cy := top_y + len * (0.3 + 0.2 * i)
                _page(Vector2(cx, cy), 1.0, px * 0.1 + i)

func _page(p: Vector2, s: float, ph: float) -> void:
        var tilt := sin(_t * 1.8 + ph) * 0.5
        var w := 7.0 * s
        var h := 10.0 * s
        var dir := 1.0 if sin(tilt) >= 0.0 else -1.0
        draw_colored_polygon(PackedVector2Array([
                p + Vector2(-w, -h * 0.2),
                p + Vector2(-w * 0.2 + dir * w * 0.8, -h),
                p + Vector2(w, -h * 0.2 + dir * h * 0.3),
                p + Vector2(w * 0.2 - dir * w * 0.5, h),
        ]), Color(E0.PARCH.r * 0.8, E0.PARCH.g * 0.8, E0.PARCH.b * 0.75, 0.34))

# ------------------------------------------------------------------ stumps

func _stump_column(px: float, base_y: float, w: float, h: float, ph: float) -> void:
        ## broken column stump in the near ground: a snapped shaft, drum
        ## courses, one flake catching the rim
        _ghost_rect(Rect2(px - w * 0.5, base_y - h, w, h))
        draw_rect(Rect2(px - w * 0.7, base_y - 12.0, w * 1.4, 14.0), SILHOUETTE)
        for i in 4:
                var t := float(i) / 4.0
                var cy := base_y - h * (1.0 - t) - 12.0
                var cw := w * (1.0 - t * 0.22)
                draw_rect(Rect2(px - cw * 0.5, cy, cw, h / 4.0 + 2.0), Color(SILHOUETTE.r, SILHOUETTE.g, SILHOUETTE.b, 0.96 - t * 0.03))
        # the snapped crown leans
        var lean := sin(_t * 0.3 + ph) * 1.5
        draw_colored_polygon(PackedVector2Array([
                Vector2(px - w * 0.4, base_y - h), Vector2(px + w * 0.36, base_y - h - 4.0 + lean),
                Vector2(px + w * 0.28, base_y - h - 26.0 + lean), Vector2(px - w * 0.3, base_y - h - 18.0),
        ]), SILHOUETTE)
        _rim_line(Vector2(px - w * 0.7, base_y - 12.0), Vector2(px + w * 0.7, base_y - 12.0))

func _stump_rubble(px: float, base_y: float, w: float, h: float, seed: float) -> void:
        ## rubble mound: seeded angular blocks — aftermath made local
        var rng := RandomNumberGenerator.new()
        rng.seed = int(seed * 999983.0)
        var blocks := 7
        for i in blocks:
                var bx := px + rng.randf_range(-w * 0.5, w * 0.5)
                var by := base_y - rng.randf_range(0.0, h * 0.7)
                var bw := rng.randf_range(w * 0.16, w * 0.34)
                var bh := rng.randf_range(h * 0.2, h * 0.5)
                var pts := PackedVector2Array([
                        Vector2(bx - bw * 0.5, by), Vector2(bx + bw * 0.2, by - bh * 0.6),
                        Vector2(bx + bw * 0.5, by - bh * 0.2), Vector2(bx + bw * 0.1, by + bh * 0.2),
                ])
                draw_colored_polygon(pts, Color(SILHOUETTE.r, SILHOUETTE.g, SILHOUETTE.b, 0.92 + rng.randf() * 0.06))
                if i < 3:
                        _rim_line(Vector2(bx - bw * 0.5, by), Vector2(bx + bw * 0.2, by - bh * 0.6))

func _stump_grate(px: float, base_y: float, w: float, h: float, ph: float) -> void:
        ## barred grate section rising from the near ground — the undercity
        ## breathing through its teeth. Faint cold draft rises between bars
        _ghost_rect(Rect2(px - w * 0.5, base_y - h, w, h))
        draw_rect(Rect2(px - w * 0.6, base_y - 10.0, w * 1.2, 12.0), SILHOUETTE)
        draw_rect(Rect2(px - w * 0.6, base_y - h, w * 1.2, 10.0), SILHOUETTE)
        var bars := maxi(3, int(w / 16.0))
        for i in bars:
                var bx := px - w * 0.5 + w * (float(i) + 0.5) / float(bars)
                draw_rect(Rect2(bx - 2.6, base_y - h, 5.2, h), Color(SILHOUETTE.r, SILHOUETTE.g, SILHOUETTE.b, 0.96))
                if i % 2 == 0:
                        var draft := sin(_t * 0.9 + ph + i) * 0.5 + 0.5
                        draw_line(Vector2(bx, base_y - h - 4.0), Vector2(bx + sin(_t + i) * 3.0, base_y - h - 26.0 - draft * 14.0),
                                Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.05 + draft * 0.05), 1.6)
        _rim_line(Vector2(px - w * 0.6, base_y - 10.0), Vector2(px + w * 0.6, base_y - 10.0))

func _stump_shelf(px: float, base_y: float, w: float, h: float, seed: float) -> void:
        ## archive shelf end: the side slab of a case too close to the
        ## camera — ledges, a few spines, one page slipping
        var rng := RandomNumberGenerator.new()
        rng.seed = int(seed * 999979.0)
        _ghost_rect(Rect2(px - w * 0.5, base_y - h, w, h))
        draw_rect(Rect2(px - w * 0.5, base_y - h, w, h), Color(SILHOUETTE.r, SILHOUETTE.g, SILHOUETTE.b, 0.97))
        _rim_line(Vector2(px - w * 0.5, base_y - h), Vector2(px - w * 0.5, base_y))
        for i in 5:
                var sy := base_y - h * (0.18 + 0.16 * i)
                draw_rect(Rect2(px - w * 0.5, sy, w, 4.0), Color(SILHOUETTE.r, SILHOUETTE.g, SILHOUETTE.b, 0.9))
                # a surviving spine or two per ledge
                var spines := rng.randi_range(1, 3)
                for s_idx in spines:
                        var sw := rng.randf_range(3.0, 6.0)
                        var sx := px - w * 0.36 + rng.randf() * w * 0.6
                        draw_rect(Rect2(sx, sy - rng.randf_range(10.0, 16.0), sw, 16.0),
                                Color(E0.PARCH.r * 0.5, E0.PARCH.g * 0.5, E0.PARCH.b * 0.45, 0.5))
        # the slipping page — one slow escapee per shelf, phased forever
        var slip := fmod(_t * 0.06 + seed, 1.0)
        draw_circle(Vector2(px + sin(slip * TAU) * 6.0, base_y - h - 20.0 - slip * 40.0), 3.0,
                Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.2 * (1.0 - slip)))

func _stump_gantry(px: float, base_y: float, w: float, h: float, ph: float) -> void:
        ## engine gantry upright: riveted iron foot, cross-brace, a warning
        ## stripe long burned to shadow
        _ghost_rect(Rect2(px - w * 0.5, base_y - h, w, h))
        draw_rect(Rect2(px - w * 0.62, base_y - 12.0, w * 1.24, 14.0), SILHOUETTE)
        draw_rect(Rect2(px - w * 0.34, base_y - h, w * 0.68, h), Color(SILHOUETTE.r, SILHOUETTE.g, SILHOUETTE.b, 0.97))
        # cross brace
        draw_line(Vector2(px - w * 0.34, base_y - h * 0.2), Vector2(px + w * 0.34, base_y - h * 0.8),
                Color(SILHOUETTE.r, SILHOUETTE.g, SILHOUETTE.b, 0.92), 5.0)
        # rivets
        for i in 4:
                var ry := base_y - 16.0 - h * 0.22 * i
                draw_circle(Vector2(px - w * 0.44, ry), 2.4, Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.10))
                draw_circle(Vector2(px + w * 0.44, ry), 2.4, Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.10))
        # heat shimmer off the iron
        var hot := 0.5 + 0.5 * sin(_t * 1.3 + ph)
        draw_line(Vector2(px - w * 0.2, base_y - h - 2.0), Vector2(px + w * 0.2, base_y - h - 2.0),
                Color(E0.CRIMSON.r, E0.CRIMSON.g, E0.CRIMSON.b, 0.05 + hot * 0.05), 2.0)
        _rim_line(Vector2(px - w * 0.62, base_y - 12.0), Vector2(px + w * 0.62, base_y - 12.0))
