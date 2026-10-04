## FloorCraft — THE GROUND YOU WALK ON. The play floor's walking surface,
## rendered as real craftsmanship: false-perspective flagstone courses with
## running-bond seams, chipped corners, sunken tiles, a pilgrimage wear path,
## and per-district recipes (chapel runner carpet + mosaic border, engine
## steel plates + rivets + welds, reliquary gold inlays, aftermath cracks,
## archive page litter, undercity damp + drainage grates, womb conduits).
## THE LEDGES: every climb platform gets a rendered slab — block body, crafted
## top surface, rough-hewn underside, and corbel brackets mounting it to the
## back wall. Before this pass the climb platforms were collision-only.
## All deterministic per room; palette-locked; static (drawn once per build).
class_name FloorCraft
extends Node2D

var key := ""
var district := ""
var style := "stone"
var floors: Array = []
var plats: Array = []

# generated craft data (regenerated per room build)
var _floor_surfaces: Array = []   # per-floor: slabs, dressing, lip
var _ledges: Array = []           # per-platform: blocks, corbels, chips

var _tex: Texture2D = null

const SLAB_W := 58.0
const SURFACE_MAX := 30.0        # walking strip depth on floors — deep
                                 # enough that floor craft READS at distance

func setup(p_key: String, p_floors: Array, p_plats: Array, p_style: String, p_district: String) -> void:
        key = p_key
        floors = p_floors
        plats = p_plats
        style = p_style
        district = p_district
        var path := "res://art/environments/tex_metal.png" if style == "metal" else "res://art/environments/tex_stone.png"
        if ResourceLoader.exists(path):
                _tex = load(path)
        z_index = 0               # same plane as masonry/decor; added between
                                   # them so dressing (puddles, glyphs) paints on top
        _generate()

func _generate() -> void:
        _floor_surfaces.clear()
        _ledges.clear()
        var rng := RandomNumberGenerator.new()
        rng.seed = hash("floorcraft:" + key)
        for r in floors:
                var rect: Rect2 = r
                _floor_surfaces.append(_craft_floor(rect, rng))
        for r in plats:
                var rect: Rect2 = r
                _ledges.append(_craft_ledge(rect, rng))
        queue_redraw()

# ------------------------------------------------------------------ floors

func _craft_floor(rect: Rect2, rng: RandomNumberGenerator) -> Dictionary:
        ## The walking surface: two courses of slabs in gentle false
        ## perspective (back course thinner, darker — it faces away), running
        ## bond seams, deterministic wear per district.
        var depth := minf(SURFACE_MAX, rect.size.y * 0.5)
        var back_h := depth * 0.58
        var front_h := depth - back_h
        var slabs: Array = []
        var slab_w := SLAB_W * (1.6 if style == "metal" else 1.0)
        var x := rect.position.x
        var col := 0
        while x < rect.end.x - 6.0:
                var w := minf(slab_w - rng.randf_range(2.0, 7.0), rect.end.x - x)
                if w < 18.0:
                        x += slab_w
                        continue
                # sunken / raised tiles: the pavement has settled unevenly
                var settled := 0.0
                var roll := rng.randf()
                if roll < 0.07:
                        settled = rng.randf_range(-1.0, 1.0)
                slabs.append({
                        "x": x, "w": w, "col": col,
                        "row": 0, "h": back_h,
                        "chip": rng.randf() < 0.26,
                        "chip_side": 1 if rng.randf() < 0.5 else -1,
                        "settled": settled,
                        "crack": rng.randf() < _crack_density(),
                        "k": 0.86 + rng.randf() * 0.22,
                })
                x += slab_w
                col += 1
        x = rect.position.x - slab_w * 0.5
        col = 0
        while x < rect.end.x - 6.0:
                var w := minf(slab_w - rng.randf_range(2.0, 7.0), rect.end.x - x)
                if w < 18.0:
                        x += slab_w
                        continue
                var settled2 := 0.0
                if rng.randf() < 0.06:
                        settled2 = rng.randf_range(-1.0, 1.0)
                slabs.append({
                        "x": x, "w": w, "col": col,
                        "row": 1, "h": front_h,
                        "chip": rng.randf() < 0.30,
                        "chip_side": 1 if rng.randf() < 0.5 else -1,
                        "settled": settled2,
                        "crack": rng.randf() < _crack_density(),
                        "k": 0.94 + rng.randf() * 0.20,
                })
                x += slab_w
                col += 1
        var d := {
                "rect": rect,
                "depth": depth,
                "back_h": back_h,
                "slabs": slabs,
                "dress": _craft_dressing(rect, depth, rng),
        }
        return d

func _crack_density() -> float:
        match district:
                "aftermath":
                        return 0.34
                "undercity":
                        return 0.20
                "engine":
                        return 0.10
                _:
                        return 0.14

func _craft_dressing(rect: Rect2, depth: float, rng: RandomNumberGenerator) -> Array:
        ## Per-district floor dressing — the recipes that make each stratum
        ## of the city its own ground. All counts scale with walk length.
        var out: Array = []
        var walk := rect.size.x
        match district:
                "vessels":
                        # the womb: cable conduits along the back edge, glow seams
                        var cx := rect.position.x + rng.randf_range(60.0, 200.0)
                        while cx < rect.end.x - 60.0:
                                out.append({"kind": "conduit", "x": cx,
                                        "len": rng.randf_range(160.0, 420.0),
                                        "glow": rng.randf() < 0.4})
                                cx += rng.randf_range(420.0, 760.0)
                        var gx := rect.position.x + rng.randf_range(200.0, 400.0)
                        while gx < rect.end.x - 80.0:
                                out.append({"kind": "grate", "x": gx})
                                gx += rng.randf_range(640.0, 1100.0)
                "undercity":
                        # it weeps: damp stains + drainage grates + moss flecks
                        var dx := rect.position.x + rng.randf_range(40.0, 200.0)
                        while dx < rect.end.x - 40.0:
                                out.append({"kind": "damp", "x": dx,
                                        "rx": rng.randf_range(30.0, 90.0),
                                        "a": rng.randf_range(0.08, 0.14)})
                                dx += rng.randf_range(200.0, 380.0)
                        var g2x := rect.position.x + rng.randf_range(120.0, 300.0)
                        while g2x < rect.end.x - 80.0:
                                out.append({"kind": "grate", "x": g2x,
                                        "wet": rng.randf() < 0.6})
                                g2x += rng.randf_range(380.0, 620.0)
                        for i in int(walk / 90.0):
                                out.append({"kind": "moss", "x": rect.position.x + rng.randf() * walk,
                                        "rx": rng.randf_range(3.0, 9.0)})
                "city":
                        # the processional way: a polished wear lane + boundary plaques
                        out.append({"kind": "wear", "x0": rect.position.x, "x1": rect.end.x})
                        var bx := rect.position.x + rng.randf_range(300.0, 600.0)
                        while bx < rect.end.x - 120.0:
                                out.append({"kind": "plaque", "x": bx})
                                bx += rng.randf_range(700.0, 1100.0)
                "chapel":
                        # the runner carpet + flanking mosaic borders
                        out.append({"kind": "carpet", "x0": rect.position.x + 14.0, "x1": rect.end.x - 14.0})
                        for i in int(walk / 46.0):
                                out.append({"kind": "tessera", "x": rect.position.x + 10.0 + rng.randf() * (walk - 20.0),
                                        "side": 1 if rng.randf() < 0.5 else -1,
                                        "pal": rng.randi() % 3})
                        for i in int(walk / 300.0) + 1:
                                out.append({"kind": "worn", "x": rect.position.x + rng.randf() * walk,
                                        "rx": rng.randf_range(16.0, 42.0)})
                "archive":
                        # the archive sheds on itself: flat pages, spilled
                        # stacks, ink stains — the floor keeps its own records
                        var px := rect.position.x + rng.randf_range(30.0, 140.0)
                        while px < rect.end.x - 30.0:
                                var stack := rng.randf() < 0.28
                                var n_pages := 2 + (rng.randi() % 3) if stack else 1
                                for i in n_pages:
                                        out.append({"kind": "page", "x": px + float(i) * rng.randf_range(5.0, 12.0),
                                                "rot": rng.randf_range(-0.35, 0.35),
                                                "fold": rng.randf() < 0.3,
                                                "off": rng.randf_range(1.0, 4.0)})
                                px += rng.randf_range(60.0, 150.0)
                        for i in int(walk / 420.0) + 1:
                                out.append({"kind": "ink", "x": rect.position.x + rng.randf() * walk,
                                        "rx": rng.randf_range(6.0, 16.0)})
                "engine":
                        # steel: rivet rows + weld seams + hazard chevrons + sheen
                        var hx := rect.position.x + rng.randf_range(240.0, 500.0)
                        while hx < rect.end.x - 140.0:
                                out.append({"kind": "hazard", "x": hx})
                                hx += rng.randf_range(760.0, 1250.0)
                        out.append({"kind": "sheen", "x0": rect.position.x, "x1": rect.end.x})
                "reliquary":
                        # pale polished stone with gold seam inlays
                        var ix := rect.position.x + 3.0 * SLAB_W
                        while ix < rect.end.x - 20.0:
                                out.append({"kind": "inlay", "x": ix})
                                ix += 4.0 * SLAB_W + rng.randf_range(-6.0, 6.0)
                        out.append({"kind": "polish", "x0": rect.position.x, "x1": rect.end.x})
                "aftermath":
                        # the broken ground: cracks, rubble, ash drifts
                        for i in int(walk / 300.0) + 2:
                                out.append({"kind": "drift", "x": rect.position.x + rng.randf() * walk,
                                        "rx": rng.randf_range(30.0, 90.0)})
                        for i in int(walk / 120.0):
                                out.append({"kind": "rubble", "x": rect.position.x + rng.randf() * walk,
                                        "s": rng.randf_range(1.4, 4.2),
                                        "dark": rng.randf() < 0.5})
        return out

# ------------------------------------------------------------------ ledges

func _craft_ledge(rect: Rect2, rng: RandomNumberGenerator) -> Dictionary:
        ## A rendered climb ledge: block body sampled from the material tile,
        ## crafted top surface, rough-hewn underside, corbel mounts. The ledge
        ## is ATTACHED to the back wall by its brackets — never floating.
        var blocks: Array = []
        var slab_w := SLAB_W * (1.5 if style == "metal" else 1.0)
        var x := rect.position.x + 1.0
        while x < rect.end.x - 8.0:
                var w := minf(slab_w - rng.randf_range(3.0, 9.0), rect.end.x - 4.0 - x)
                if w < 16.0:
                        break
                blocks.append({
                        "x": x, "w": w,
                        "k": 0.88 + rng.randf() * 0.20,
                        "uv": Vector2(rng.randf() * 4096.0, rng.randf() * 4096.0),
                        "chip": rng.randf() < 0.30,
                })
                x += slab_w
        # corbels: both ends + middle when wide — two-step stone brackets
        var corbels: Array = []
        var c_x := rect.position.x + 8.0
        var end_x := rect.end.x - 8.0
        while c_x <= end_x:
                corbels.append({"x": c_x, "s": 0.8 + rng.randf() * 0.4})
                if end_x - c_x < 150.0:
                        break
                c_x += minf(210.0, end_x - c_x)
        var chips: Array = []
        for cx in range(int(rect.position.x + 10.0), int(rect.end.x - 6.0), 34):
                if rng.randf() < 0.34:
                        chips.append({"x": float(cx) + rng.randf() * 12.0,
                                "s": rng.randf_range(1.2, 3.4)})
        return {"rect": rect, "blocks": blocks, "corbels": corbels, "chips": chips}

# ------------------------------------------------------------------ draw

func _draw() -> void:
        for f in _floor_surfaces:
                _draw_floor(f)
        for l in _ledges:
                _draw_ledge(l)

func _draw_floor(f: Dictionary) -> void:
        var rect: Rect2 = f["rect"]
        var depth: float = f["depth"]
        var back_h: float = f["back_h"]
        var y0 := rect.position.y
        var tw := 512.0
        var th := 512.0
        if _tex:
                tw = float(_tex.get_width())
                th = float(_tex.get_height())
        # ---- the walking surface: slab courses in false perspective
        for s in f["slabs"]:
                var sx: float = s["x"]
                var sw: float = s["w"]
                var sy := y0 if int(s["row"]) == 0 else y0 + back_h
                var sh: float = s["h"]
                var settled: float = s["settled"]
                sy += settled
                var k: float = s["k"]
                # back course sits a touch darker (faces away from the eye)
                if int(s["row"]) == 0:
                        k *= 0.90
                var dst := Rect2(Vector2(sx, sy), Vector2(sw, sh))
                if _tex:
                        var uv: Vector2 = Vector2(sx * 0.37, sy * 0.61 + float(s["col"]) * 17.0)
                        var src := Rect2(fmod(uv.x, tw - sw - 2.0), fmod(uv.y, th - sh - 2.0), sw, sh)
                        draw_texture_rect_region(_tex, dst, src, Color(k, k, k, 1.0))
                else:
                        var col := Color(E0.DIRTY_STONE.r * k, E0.DIRTY_STONE.g * k, E0.DIRTY_STONE.b * k)
                        draw_rect(dst, col)
                # seam shadows: bottom + one side — running bond light logic
                draw_rect(Rect2(dst.position + Vector2(0, sh - 1.5), Vector2(sw, 1.5)),
                        Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.38))
                var seam_x := dst.position.x + (1.0 if int(s["col"]) % 2 == 0 else sw - 1.0)
                draw_rect(Rect2(Vector2(seam_x, sy), Vector2(1.0, sh)),
                        Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.26))
                # settled tile edge — the little shadow that says "it sank"
                if absf(settled) > 0.4:
                        draw_rect(Rect2(Vector2(sx, sy + (0.6 if settled < 0.0 else 0.0)), Vector2(sw, 0.8)),
                                Color(0.9, 0.88, 0.82, 0.10 if settled > 0.0 else 0.0))
                # chipped corner: a dark notch eating into the slab
                if s["chip"]:
                        var side: float = s["chip_side"]
                        var cx := sx + (sw - 8.0 if side > 0 else 0.0)
                        draw_colored_polygon(PackedVector2Array([
                                Vector2(cx, sy + sh),
                                Vector2(cx + 7.0 * side, sy + sh),
                                Vector2(cx + 5.0 * side, sy + sh - 3.4),
                                Vector2(cx + 1.5 * side, sy + sh - 4.2),
                        ]), Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.42))
                # surface crack
                if s["crack"]:
                        var cxx := sx + sw * (0.3 + 0.4 * fmod(absf(sx) * 0.017, 1.0))
                        draw_line(Vector2(cxx, sy + 1.5), Vector2(cxx - 3.0, sy + sh - 1.5),
                                Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.5), 1.0)
        # ---- back edge: where the floor meets the far plane, it darkens
        # (the veil's shadow grounds the floor into the depth sandwich)
        for i in 3:
                var t := float(i) / 3.0
                draw_rect(Rect2(rect.position.x, y0 + t * back_h * 0.6, rect.size.x, back_h * 0.25),
                        Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.10 - 0.028 * t))
        # top light catch at the very back edge
        draw_rect(Rect2(rect.position.x, y0, rect.size.x, 1.2),
                Color(0.9, 0.88, 0.82, 0.10))
        # ---- front lip: the carved edge where surface meets the cliff face
        var lip_y := y0 + depth
        draw_rect(Rect2(rect.position.x, lip_y - 1.6, rect.size.x, 1.6),
                Color(0.9, 0.88, 0.82, 0.13))
        draw_rect(Rect2(rect.position.x, lip_y, rect.size.x, 2.2),
                Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.34))
        _draw_dressing(f, y0, depth)

func _draw_dressing(f: Dictionary, y0: float, depth: float) -> void:
        var rect: Rect2 = f["rect"]
        var mid_y := y0 + depth * 0.55
        for d in f["dress"]:
                match String(d["kind"]):
                        "wear":
                                # the pilgrimage groove: a darker polished lane
                                var x0: float = d["x0"]
                                var x1: float = d["x1"]
                                draw_rect(Rect2(x0, y0 + depth * 0.30, x1 - x0, depth * 0.42),
                                        Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.13))
                                # sheen line — ten thousand feet polished it
                                draw_rect(Rect2(x0, y0 + depth * 0.34, x1 - x0, 1.0),
                                        Color(0.9, 0.88, 0.82, 0.05))
                        "plaque":
                                # boundary plaque set into the pavement
                                var px: float = d["x"]
                                draw_rect(Rect2(px - 6.0, mid_y - 3.0, 12.0, 6.0),
                                        E0.ASH.darkened(0.15))
                                draw_rect(Rect2(px - 4.2, mid_y - 1.6, 8.4, 3.2),
                                        Color(E0.BLOOD.r, E0.BLOOD.g, E0.BLOOD.b, 0.8))
                                draw_circle(Vector2(px, mid_y), 0.8, Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.6))
                        "carpet":
                                # the chapel runner: crimson with gold borders
                                var cx0: float = d["x0"]
                                var cx1: float = d["x1"]
                                var cy := y0 + depth * 0.22
                                var ch := depth * 0.62
                                draw_rect(Rect2(cx0, cy, cx1 - cx0, ch),
                                        Color(E0.BLOOD.r * 0.9, E0.BLOOD.g * 0.9, E0.BLOOD.b * 0.9, 0.88))
                                # woven texture: faint horizontal thread bands
                                for i in int(ch / 4.0):
                                        draw_rect(Rect2(cx0, cy + float(i) * 4.0, cx1 - cx0, 1.0),
                                                Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.10))
                                # gold borders, both edges — lit by the censer
                                # glow, studded so the rhythm reads at distance
                                for bx in [cx0 + 1.0, cx1 - 4.2]:
                                        draw_rect(Rect2(bx, cy, 3.2, ch),
                                                Color(E0.GOLD.r * 1.12, E0.GOLD.g * 1.08, E0.GOLD.b * 0.9, 0.9))
                                        draw_rect(Rect2(bx - 1.8, cy, 1.0, ch),
                                                Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.45))
                                # inner hairline — the weaver signed the runner twice
                                for bx2 in [cx0 + 6.0, cx1 - 8.0]:
                                        draw_rect(Rect2(bx2, cy + 2.0, 1.2, ch - 4.0),
                                                Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.38))
                                # border studs — gold dots, big enough to catch
                                # the candle light at gameplay distance
                                for sx3 in [cx0 + 2.6, cx1 - 2.6]:
                                        var sy3 := cy + 3.0
                                        while sy3 < cy + ch - 2.0:
                                                draw_circle(Vector2(sx3, sy3), 1.7,
                                                        Color(E0.GOLD.r * 1.25, E0.GOLD.g * 1.15, E0.GOLD.b * 0.85, 0.9))
                                                draw_circle(Vector2(sx3, sy3), 0.8,
                                                        Color(E0.BONE.r, E0.BONE.g, E0.BONE.b, 0.5))
                                                sy3 += 10.0
                                # fringe at both ends of the runner
                                for ex in [cx0, cx1]:
                                        for i in int(ch / 3.0):
                                                draw_line(Vector2(ex, cy + 2.0 + float(i) * 3.0),
                                                        Vector2(ex + (4.0 if ex == cx0 else -4.0), cy + 3.4 + float(i) * 3.0),
                                                        Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.30), 1.0)
                        "tessera":
                                # mosaic border flanking the runner
                                var tx: float = d["x"]
                                var side: float = d["side"]
                                var pal: int = d["pal"]
                                var tcol := Color(E0.VIOLET.r, E0.VIOLET.g, E0.VIOLET.b, 0.5)
                                if pal == 1:
                                        tcol = Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.42)
                                elif pal == 2:
                                        tcol = Color(E0.BLOOD.r, E0.BLOOD.g, E0.BLOOD.b, 0.55)
                                var ty := y0 + depth * (0.06 if side > 0 else 0.88)
                                draw_rect(Rect2(tx, ty, 2.4, 2.4), tcol)
                        "worn":
                                # threadbare spots on the carpet
                                var wx: float = d["x"]
                                var wrx: float = d["rx"]
                                _ellipse(Vector2(wx, y0 + depth * 0.5), wrx, wrx * 0.3,
                                        Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.16))
                        "conduit":
                                # the womb's cabled floor: a pipe run + clamps
                                var kx: float = d["x"]
                                var klen: float = d["len"]
                                var ky := y0 + depth * 0.14
                                draw_rect(Rect2(kx, ky, klen, 3.2), E0.ASH)
                                for cx in range(int(kx + 14.0), int(kx + klen - 8.0), 90):
                                        draw_rect(Rect2(float(cx), ky - 1.2, 3.0, 5.6), E0.DIRTY_STONE)
                                if d["glow"]:
                                        # a live seam: faint cyan bleed at a joint
                                        var jx := kx + klen * 0.5
                                        draw_rect(Rect2(jx - 1.0, ky - 1.0, 2.0, 5.0),
                                                Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.35))
                                        _ellipse(Vector2(jx, ky + 2.0), 10.0, 3.0,
                                                Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.08))
                        "grate":
                                # drainage grate set into the pavement — wide
                                # enough to read at a glance, wet sheen around
                                var gx: float = d["x"]
                                var gy := y0 + depth * 0.62
                                if d.get("wet", false):
                                        _ellipse(Vector2(gx, gy + 1.0), 34.0, 7.0,
                                                Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.05))
                                draw_rect(Rect2(gx - 20.0, gy - 3.2, 40.0, 7.6), E0.ASH.darkened(0.2))
                                draw_rect(Rect2(gx - 20.0, gy - 3.2, 40.0, 1.6), Color(0.9, 0.88, 0.82, 0.16))
                                draw_rect(Rect2(gx - 20.0, gy + 2.4, 40.0, 1.4), Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.5))
                                for i in 7:
                                        draw_rect(Rect2(gx - 16.0 + float(i) * 4.6, gy - 1.6, 2.6, 4.4),
                                                Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.88))
                                # one slot catches the wet light
                                draw_rect(Rect2(gx - 16.0 + 3.0 * 4.6, gy - 1.6, 2.6, 4.4),
                                        Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.22))
                        "damp":
                                var dxx: float = d["x"]
                                var drx: float = d["rx"]
                                var da: float = d["a"]
                                _ellipse(Vector2(dxx, y0 + depth * 0.7), drx, drx * 0.24,
                                        Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, da))
                        "moss":
                                var mx: float = d["x"]
                                var mrx: float = d["rx"]
                                _ellipse(Vector2(mx, y0 + depth * 0.8), mrx, mrx * 0.4,
                                        Color(E0.PARCH.r * 0.7, E0.PARCH.g * 0.82, E0.PARCH.b * 0.6, 0.10))
                        "page":
                                # a fallen record, flat on the stone — bright
                                # enough to read as A PAGE in the dark archive
                                var px2: float = d["x"]
                                var rot: float = d["rot"]
                                var off: float = d.get("off", 0.0)
                                draw_set_transform(Vector2(px2, y0 + depth * 0.56 + off), rot, Vector2.ONE)
                                draw_rect(Rect2(-8.0, -10.0, 16.0, 20.0),
                                        Color(E0.PARCH.r * 1.08, E0.PARCH.g * 1.08, E0.PARCH.b * 1.04, 0.95))
                                # catching edge — paper catches what light there is
                                draw_rect(Rect2(-8.0, -10.0, 16.0, 1.8),
                                        Color(E0.BONE.r, E0.BONE.g, E0.BONE.b, 0.6))
                                draw_rect(Rect2(-8.0, -10.0, 1.6, 20.0),
                                        Color(E0.BONE.r, E0.BONE.g, E0.BONE.b, 0.3))
                                if d["fold"]:
                                        draw_rect(Rect2(-8.0, -10.0, 16.0, 8.0),
                                                Color(E0.PARCH.r * 0.78, E0.PARCH.g * 0.78, E0.PARCH.b * 0.82, 0.8))
                                # filed lines — a life, written and closed
                                for i in 4:
                                        draw_rect(Rect2(-5.0 + float(i % 2) * 2.8, -6.5 + float(i) * 3.4, 4.6, 1.2),
                                                Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.5))
                                draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
                        "ink":
                                var ix: float = d["x"]
                                var irx: float = d["rx"]
                                _ellipse(Vector2(ix, y0 + depth * 0.66), irx, irx * 0.3,
                                        Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.13))
                        "hazard":
                                # engine chevron strip — mind the machines
                                var hx: float = d["x"]
                                var hy := y0 + depth * 0.5
                                for i in 7:
                                        var cxx := hx + float(i) * 9.0
                                        draw_line(Vector2(cxx, hy - 4.0), Vector2(cxx + 5.0, hy + 4.0),
                                                Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.34), 2.8)
                        "sheen":
                                # oil sheen on steel: a faint forward reflection band
                                var sx0: float = d["x0"]
                                var sx1: float = d["x1"]
                                draw_rect(Rect2(sx0, y0 + depth * 0.72, sx1 - sx0, depth * 0.22),
                                        Color(0.9, 0.88, 0.82, 0.035))
                        "inlay":
                                # reliquary: a gold seam where slabs meet
                                var ix2: float = d["x"]
                                draw_rect(Rect2(ix2, y0 + 1.5, 1.6, depth - 3.0),
                                        Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.48))
                                draw_rect(Rect2(ix2 - 1.2, y0 + 1.5, 0.8, depth - 3.0),
                                        Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.35))
                        "polish":
                                var px0: float = d["x0"]
                                var px1: float = d["x1"]
                                draw_rect(Rect2(px0, y0 + depth * 0.10, px1 - px0, depth * 0.84),
                                        Color(E0.BONE.r, E0.BONE.g, E0.BONE.b, 0.085))
                                # a pale catching line where the polish meets
                                # the lip — the sanctum floor is KEPT, swept
                                draw_rect(Rect2(px0, y0 + depth * 0.16, px1 - px0, 1.0),
                                        Color(E0.BONE.r, E0.BONE.g, E0.BONE.b, 0.10))
                        "drift":
                                # aftermath: an ash mound poured across the
                                # slabs — city ash, grey-dark, never snow
                                var ax: float = d["x"]
                                var arx: float = d["rx"]
                                var dc := Color(E0.ASH.r * 0.9 + 0.05, E0.ASH.g * 0.9 + 0.05, E0.ASH.b * 0.9 + 0.06, 0.22)
                                var pts := PackedVector2Array()
                                for i in 10:
                                        var ang := PI * float(i) / 9.0
                                        pts.append(Vector2(ax, y0 + depth * 0.85) + Vector2(cos(ang) * arx, -sin(ang) * arx * 0.16))
                                pts.append(Vector2(ax - arx, y0 + depth * 0.9))
                                pts.append(Vector2(ax + arx, y0 + depth * 0.9))
                                draw_colored_polygon(pts, dc)
                                # ember flecks in the drift — it is still warm
                                for i in 3:
                                        var ex := ax + (float(i) - 1.0) * arx * 0.4
                                        draw_circle(Vector2(ex, y0 + depth * 0.82), 0.8,
                                                Color(E0.CRIMSON.r + 0.3, E0.CRIMSON.g * 0.7, E0.CRIMSON.b * 0.4, 0.35))
                        "rubble":
                                var rx2: float = d["x"]
                                var rs: float = d["s"]
                                var rcol := E0.ASH if bool(d["dark"]) else E0.DIRTY_STONE
                                draw_colored_polygon(PackedVector2Array([
                                        Vector2(rx2 - rs, y0 + depth * 0.7),
                                        Vector2(rx2 - rs * 0.3, y0 + depth * 0.7 - rs),
                                        Vector2(rx2 + rs * 0.5, y0 + depth * 0.7 - rs * 0.7),
                                        Vector2(rx2 + rs, y0 + depth * 0.7),
                                ]), Color(rcol.r, rcol.g, rcol.b, 0.55))

func _draw_ledge(l: Dictionary) -> void:
        var rect: Rect2 = l["rect"]
        var y0 := rect.position.y
        var h := rect.size.y
        var tw := 512.0
        var th := 512.0
        if _tex:
                tw = float(_tex.get_width())
                th = float(_tex.get_height())
        # corbel mounts FIRST — they sit behind/under the slab
        for c in l["corbels"]:
                var cx: float = c["x"]
                var cs: float = c["s"]
                # two-step bracket descending from the slab underside
                draw_colored_polygon(PackedVector2Array([
                        Vector2(cx - 7.0 * cs, y0 + h),
                        Vector2(cx + 7.0 * cs, y0 + h),
                        Vector2(cx + 4.4 * cs, y0 + h + 9.0 * cs),
                        Vector2(cx - 4.4 * cs, y0 + h + 9.0 * cs),
                ]), E0.DIRTY_STONE.darkened(0.08))
                draw_colored_polygon(PackedVector2Array([
                        Vector2(cx - 4.4 * cs, y0 + h + 9.0 * cs),
                        Vector2(cx + 4.4 * cs, y0 + h + 9.0 * cs),
                        Vector2(cx + 2.4 * cs, y0 + h + 14.0 * cs),
                        Vector2(cx - 2.4 * cs, y0 + h + 14.0 * cs),
                ]), E0.DIRTY_STONE.darkened(0.16))
                draw_rect(Rect2(cx - 7.0 * cs, y0 + h - 1.0, 14.0 * cs, 1.4),
                        Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.4))
        # the slab body: material blocks
        for b in l["blocks"]:
                var bx: float = b["x"]
                var bw: float = b["w"]
                var k: float = b["k"]
                var dst := Rect2(Vector2(bx, y0 + 3.0), Vector2(bw, h - 3.0))
                if _tex:
                        var uv: Vector2 = b["uv"]
                        var src := Rect2(fmod(uv.x, tw - bw - 2.0), fmod(uv.y, th - (h - 3.0) - 2.0), bw, h - 3.0)
                        draw_texture_rect_region(_tex, dst, src, Color(k, k, k, 1.0))
                else:
                        draw_rect(dst, Color(E0.DIRTY_STONE.r * k, E0.DIRTY_STONE.g * k, E0.DIRTY_STONE.b * k))
                # mortar shadow under each block
                draw_rect(Rect2(dst.position + Vector2(0, h - 4.5), Vector2(bw, 1.6)),
                        Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.42))
                if b["chip"]:
                        draw_colored_polygon(PackedVector2Array([
                                Vector2(bx + bw - 7.0, y0 + h),
                                Vector2(bx + bw, y0 + h),
                                Vector2(bx + bw - 1.0, y0 + h - 3.6),
                        ]), Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.45))
        # crafted top surface: a 3px dressed strip + light catch
        draw_rect(Rect2(rect.position.x + 1.0, y0 + 1.0, rect.size.x - 2.0, 3.0),
                Color(E0.DIRTY_STONE.r * 1.12, E0.DIRTY_STONE.g * 1.12, E0.DIRTY_STONE.b * 1.1, 0.9))
        draw_rect(Rect2(rect.position.x + 1.0, y0, rect.size.x - 2.0, 1.4),
                Color(0.9, 0.88, 0.82, 0.16))
        # top back edge: slight AO — the slab sits in the veil's shadow
        draw_rect(Rect2(rect.position.x, y0, 3.5, 1.0),
                Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.3))
        # underside chips + mortar line
        draw_rect(Rect2(rect.position.x + 1.0, y0 + h - 1.6, rect.size.x - 2.0, 1.6),
                Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.5))
        for c in l["chips"]:
                var chx: float = c["x"]
                var chs: float = c["s"]
                draw_circle(Vector2(chx, y0 + h + chs * 0.4), chs * 0.5,
                        Color(E0.ASH.r, E0.ASH.g, E0.ASH.b, 0.4))

func _ellipse(c: Vector2, rx: float, ry: float, col: Color) -> void:
        var pts := PackedVector2Array()
        for i in 12:
                var ang := TAU * i / 12.0
                pts.append(c + Vector2(cos(ang) * rx, sin(ang) * ry))
        draw_colored_polygon(pts, col)

# ------------------------------------------------------------------ queries
# (smoke tests and proofs read these — the invisible-ledge regression
# can never happen again)

func ledge_count() -> int:
        return _ledges.size()

func floor_surface_count() -> int:
        return _floor_surfaces.size()

func has_dressing(kind: String) -> bool:
        for f in _floor_surfaces:
                for d in f["dress"]:
                        if String(d["kind"]) == kind:
                                return true
        return false

func dressing_count(kind: String) -> int:
        var n := 0
        for f in _floor_surfaces:
                for d in f["dress"]:
                        if String(d["kind"]) == kind:
                                n += 1
        return n
