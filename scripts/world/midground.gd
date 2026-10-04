## Midground — the depth plane between the painted backdrop and the play
## floor. Deterministic dark silhouettes (rooflines, monoliths, gantries,
## lancets) that scroll at half camera speed, tinted toward the room fog and
## melting into the air above the walkway. Fully procedural by design: distant
## masses read correctly as flat dark shapes; the painted art stays for actors.
class_name Midground
extends Node2D

var key := ""
var _room_width := 1280.0
var _room_height := 720.0
var _horizon := 560.0
var _fog := E0.VOID
var _camera: Camera2D
var _last_cam := Vector2.ZERO

# motif silhouettes are generated once per room, cached as polygon strips
var _structures: Array = []       # {"x","w","h","kind","ph"}
var _overhead: Array = []         # cables / chains spanning between structures

const SCROLL_K := 0.5             # half camera speed — mid distance
const Y_K := 0.3

func setup(backdrop_key: String, room_size: Vector2, horizon_y: float, fog: Color, camera: Camera2D) -> void:
        key = backdrop_key
        _room_width = room_size.x
        _room_height = room_size.y
        _horizon = horizon_y
        _fog = fog
        _camera = camera
        _generate()
        z_index = -5
        queue_redraw()

func _generate() -> void:
        _structures.clear()
        _overhead.clear()
        var rng := RandomNumberGenerator.new()
        rng.seed = hash("midground:" + key)
        # span the full parallax-lagged traversal (half-speed plane) — the
        # +1500 margin guarantees coverage to the far right end of every room
        var x := -320.0
        var end_x := _room_width * 0.5 + 1500.0
        while x < end_x:
                var w := rng.randf_range(70.0, 190.0)
                var h := rng.randf_range(120.0, 330.0)
                var kind := _pick_kind(rng)
                var st := {
                        "x": x, "w": w, "h": h, "kind": kind,
                        "ph": rng.randf() * TAU,
                        "lean": rng.randf_range(-0.02, 0.02),
                        # depth within the plane: farther masses are fainter
                        "a": 0.68 + 0.32 * rng.randf(),
                }
                # lit windows — the city is inhabited, or was
                if (key == "city" or key == "undercity" or key == "archive") \
                                and (kind == "roof" or kind == "chimney" or kind == "block") \
                                and rng.randf() < 0.38 and h > 150.0:
                        st["win"] = Vector2(rng.randf_range(0.18, 0.82), rng.randf_range(0.25, 0.75))
                        st["win_warm"] = rng.randf() < 0.7
                # inner structure: big masses carry faint floor lines and the
                # rare lit slit — a black box is a missing asset, not a city
                if (kind == "block" or kind == "monolith" or kind == "tank" \
                                or kind == "ruin" or kind == "shelf" or kind == "cabinet") and h > 140.0:
                        st["inner"] = true
                        if rng.randf() < 0.4:
                                st["slit"] = Vector2(rng.randf_range(0.2, 0.8), rng.randf_range(0.3, 0.7))
                                st["slit_cold"] = rng.randf() < 0.45
                _structures.append(st)
                # gaps — the eye needs air between the masses
                x += w + rng.randf_range(24.0, 150.0)
                # occasional overhead span between neighbours
                if rng.randf() < 0.34:
                        _overhead.append({
                                "x": x - rng.randf_range(0.0, 40.0),
                                "len": rng.randf_range(120.0, 320.0),
                                "sag": rng.randf_range(18.0, 52.0),
                                "chain": rng.randf() < 0.5,
                        })

func _pick_kind(rng: RandomNumberGenerator) -> String:
        match key:
                "city":
                        return ["roof", "roof", "chimney", "pole"][rng.randi() % 4]
                "chapel":
                        return ["lancet", "lancet", "block", "cross"][rng.randi() % 4]
                "engine":
                        return ["gantry", "wheel", "gantry", "tank"][rng.randi() % 4]
                "archive":
                        return ["shelf", "shelf", "cabinet", "block"][rng.randi() % 4]
                "aftermath":
                        return ["ruin", "beam", "ruin"][rng.randi() % 3]
                _:
                        return ["monolith", "monolith", "arch", "block"][rng.randi() % 4]

func _process(_delta: float) -> void:
        if _camera:
                _last_cam = _camera.global_position
        queue_redraw()

func _draw() -> void:
        var scroll := Vector2(_last_cam.x * SCROLL_K, _last_cam.y * Y_K)
        var base_body := Color(E0.CHARCOAL.r, E0.CHARCOAL.g, E0.CHARCOAL.b, 0.62)
        var fog_k := 0.35
        # the open-air rooms sit further away in the air — lighter, hazier
        if key == "city" or key == "aftermath":
                base_body.a = 0.44
                fog_k = 0.52
        base_body = base_body.lerp(Color(_fog.r, _fog.g, _fog.b), fog_k)
        var edge := Color(E0.ASH.r, E0.ASH.g, E0.ASH.b, 0.20)
        var base_y := _horizon + 6.0 - scroll.y
        var tnow := Time.get_ticks_msec() * 0.001
        for s in _structures:
                var sx: float = s["x"] - scroll.x
                var sw: float = s["w"]
                var sh: float = s["h"]
                var top := base_y - sh
                # per-structure depth alpha — the plane stops being wallpaper
                var body := Color(base_body.r, base_body.g, base_body.b, base_body.a * float(s["a"]))
                match String(s["kind"]):
                        "roof":
                                _poly([Vector2(sx, base_y), Vector2(sx, top + 26.0), Vector2(sx + sw * 0.5, top), Vector2(sx + sw, top + 26.0), Vector2(sx + sw, base_y)], body)
                                _hline(sx + 8.0, sx + sw - 8.0, top + 27.0, edge)
                        "chimney":
                                _poly([Vector2(sx, base_y), Vector2(sx, top), Vector2(sx + sw, top), Vector2(sx + sw, base_y)], body)
                                _poly([Vector2(sx + sw * 0.2, top), Vector2(sx + sw * 0.28, top - 26.0), Vector2(sx + sw * 0.42, top - 26.0), Vector2(sx + sw * 0.5, top)], body)
                        "pole":
                                var pw := 5.0
                                _poly([Vector2(sx, base_y), Vector2(sx, top), Vector2(sx + pw, top), Vector2(sx + pw, base_y)], body)
                                _poly([Vector2(sx - 14.0, top + 12.0), Vector2(sx - 14.0, top + 18.0), Vector2(sx + pw + 14.0, top + 18.0), Vector2(sx + pw + 14.0, top + 12.0)], body)
                        "lancet":
                                var half := sw * 0.5
                                var pts := PackedVector2Array()
                                pts.append(Vector2(sx, base_y))
                                pts.append(Vector2(sx, top + 40.0))
                                # pointed arch
                                var steps := 7
                                for i in steps + 1:
                                        var t := float(i) / float(steps)
                                        var ax := sx + t * sw
                                        var ay := top + 40.0 - sin(t * PI) * 44.0 - (1.0 - absf(t - 0.5) * 2.0) * 6.0
                                        var pnt := Vector2(ax, ay)
                                        if pts.size() < 2 or pnt.distance_to(pts[pts.size() - 1]) > 0.5:
                                                pts.append(pnt)
                                pts.append(Vector2(sx + sw, top + 40.0))
                                pts.append(Vector2(sx + sw, base_y))
                                _poly(pts, body)
                                _hline(sx + 6.0, sx + sw - 6.0, top + 41.0, edge)
                        "cross":
                                _poly([Vector2(sx, base_y), Vector2(sx, top), Vector2(sx + sw, top), Vector2(sx + sw, base_y)], body)
                                var cx := sx + sw * 0.5
                                _poly([Vector2(cx - 3.0, top - 40.0), Vector2(cx - 3.0, top - 8.0), Vector2(cx + 3.0, top - 8.0), Vector2(cx + 3.0, top - 40.0)], body)
                                _poly([Vector2(cx - 16.0, top - 30.0), Vector2(cx - 16.0, top - 24.0), Vector2(cx + 16.0, top - 24.0), Vector2(cx + 16.0, top - 30.0)], body)
                        "gantry":
                                _poly([Vector2(sx, base_y), Vector2(sx, top), Vector2(sx + 10.0, top), Vector2(sx + 10.0, base_y)], body)
                                _poly([Vector2(sx + sw - 10.0, base_y), Vector2(sx + sw - 10.0, top), Vector2(sx + sw, top), Vector2(sx + sw, base_y)], body)
                                _poly([Vector2(sx, top), Vector2(sx, top + 9.0), Vector2(sx + sw, top + 9.0), Vector2(sx + sw, top)], body)
                                # diagonal brace
                                draw_line(Vector2(sx + 10.0, top + 9.0), Vector2(sx + sw - 10.0, top + 34.0), Color(body.r, body.g, body.b, body.a * 0.8), 3.0)
                        "wheel":
                                _poly([Vector2(sx, base_y), Vector2(sx, top + 30.0), Vector2(sx + sw, top + 30.0), Vector2(sx + sw, base_y)], body)
                                var c := Vector2(sx + sw * 0.5, top + 30.0)
                                var r := minf(sw * 0.42, 34.0)
                                draw_arc(c, r, PI, TAU, 14, body, 7.0)
                                draw_line(Vector2(c.x - r, c.y), Vector2(c.x + r, c.y), Color(body.r, body.g, body.b, body.a * 0.7), 3.0)
                        "tank":
                                var r2 := minf(sw * 0.5, sh * 0.5)
                                draw_circle(Vector2(sx + sw * 0.5, base_y - r2), r2, body)
                                _poly([Vector2(sx + sw * 0.5 - 6.0, base_y - r2 * 2.0), Vector2(sx + sw * 0.5 - 6.0, base_y), Vector2(sx + sw * 0.5 + 6.0, base_y), Vector2(sx + sw * 0.5 + 6.0, base_y - r2 * 2.0)], body)
                        "shelf":
                                _poly([Vector2(sx, base_y), Vector2(sx, top), Vector2(sx + sw, top), Vector2(sx + sw, base_y)], body)
                                for k in int(sh / 34.0):
                                        var ly := top + 16.0 + float(k) * 34.0
                                        draw_rect(Rect2(sx + 7.0, ly, sw - 14.0, 3.0), Color(E0.ASH.r, E0.ASH.g, E0.ASH.b, 0.14))
                        "cabinet":
                                _poly([Vector2(sx, base_y), Vector2(sx, top), Vector2(sx + sw, top), Vector2(sx + sw, base_y)], body)
                                draw_rect(Rect2(sx + sw * 0.5 - 1.5, top + 8.0, 3.0, sh - 16.0), Color(E0.ASH.r, E0.ASH.g, E0.ASH.b, 0.12))
                        "monolith":
                                var lean: float = s["lean"]
                                _poly([Vector2(sx, base_y), Vector2(sx + lean * sh, top), Vector2(sx + sw + lean * sh, top), Vector2(sx + sw, base_y)], body)
                                _hline(sx + 4.0 + lean * sh, sx + sw - 4.0 + lean * sh, top + 1.0, edge)
                        "arch":
                                var pts2 := PackedVector2Array([Vector2(sx, base_y), Vector2(sx, top + 50.0)])
                                var st := 6
                                for i in st:
                                        var t2 := float(i + 1) / float(st)
                                        var pt := Vector2(sx + t2 * sw, top + 50.0 - sin(t2 * PI) * 52.0)
                                        if pt.distance_to(pts2[pts2.size() - 1]) > 0.5:
                                                pts2.append(pt)
                                pts2.append(Vector2(sx + sw, top + 50.0))
                                pts2.append(Vector2(sx + sw, base_y))
                                _poly(pts2, body)
                        "ruin":
                                _poly([Vector2(sx, base_y), Vector2(sx + 6.0, top + 34.0), Vector2(sx + sw * 0.6, top), Vector2(sx + sw, top + 60.0), Vector2(sx + sw, base_y)], body)
                        "beam":
                                var bl: float = s["lean"] * 8.0
                                _poly([Vector2(sx, base_y), Vector2(sx + 12.0 + bl * 20.0, top), Vector2(sx + 26.0 + bl * 20.0, top), Vector2(sx + 14.0, base_y)], body)
                        "rubble":
                                # low mound cluster, squashed — reads as
                                # distant debris, never as a hard black disc
                                var rr := sw * 0.5
                                _mound(Vector2(sx + rr, base_y - 8.0), rr, body)
                                _mound(Vector2(sx + rr * 0.55, base_y - 5.0), rr * 0.55, body)
                                _mound(Vector2(sx + rr * 1.4, base_y - 4.0), rr * 0.4, body)
                        _:
                                _poly([Vector2(sx, base_y), Vector2(sx, top), Vector2(sx + sw, top), Vector2(sx + sw, base_y)], body)
                # inner structure: faint floor lines inside the big masses
                if s.has("inner") and sh > 140.0:
                        var ib := Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.045)
                        for k in range(2, int(sh / 46.0), 2):
                                var iy := top + float(k) * 46.0
                                if iy < base_y - 14.0:
                                        draw_line(Vector2(sx + 5.0, iy), Vector2(sx + sw - 5.0, iy), ib, 1.0)
                # the rare lit slit — life behind the mass
                if s.has("slit"):
                        var sl: Vector2 = s["slit"]
                        var slx := sx + sl.x * sw
                        var sly := top + sl.y * sh
                        var breathe := 0.6 + 0.4 * sin(tnow * 0.6 + float(s["ph"]) * 5.0)
                        var scol := Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.16 * breathe) if s.get("slit_cold", false) \
                                else Color(E0.GOLD.r, E0.GOLD.g * 0.9, E0.GOLD.b * 0.55, 0.18 * breathe)
                        draw_rect(Rect2(slx, sly, 2.0, 4.0), scol)
                        draw_rect(Rect2(slx - 1.6, sly - 2.0, 5.2, 8.0), Color(scol.r, scol.g, scol.b, scol.a * 0.3))
                # lit window — a lived-in dark
                if s.has("win"):
                        var wp: Vector2 = s["win"]
                        var wx := sx + wp.x * sw
                        var wy := top + wp.y * sh
                        var flick := 0.7 + 0.3 * sin(tnow * 0.8 + float(s["ph"]) * 3.0)
                        var wcol := Color(E0.GOLD.r, E0.GOLD.g * 0.9, E0.GOLD.b * 0.55, 0.34 * flick) if s.get("win_warm", true) \
                                else Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.26 * flick)
                        draw_rect(Rect2(wx, wy, 3.0, 5.0), wcol)
                        draw_rect(Rect2(wx - 2.0, wy - 2.0, 7.0, 9.0), Color(wcol.r, wcol.g, wcol.b, wcol.a * 0.28))
        # overhead spans — cables and chains stitching the skyline together
        for o in _overhead:
                var ox: float = o["x"] - scroll.x
                var otop := base_y - 340.0
                var olen: float = o["len"]
                var sag: float = o["sag"]
                var prev := Vector2(ox, otop)
                var segs := 8
                for i in segs:
                        var t := float(i + 1) / float(segs)
                        var p := Vector2(ox + olen * t, otop + sin(t * PI) * sag)
                        if o["chain"]:
                                # chain: short straight links
                                draw_line(prev, p, Color(base_body.r, base_body.g, base_body.b, 0.5), 2.0)
                        else:
                                draw_line(prev, (prev + p) * 0.5, Color(base_body.r, base_body.g, base_body.b, 0.34), 1.5)
                                draw_line((prev + p) * 0.5, p, Color(base_body.r, base_body.g, base_body.b, 0.34), 1.5)
                        prev = p
        # atmospheric perspective: haze thickens with height — the tops of the
        # masses melt into the air instead of ending at a ruler line
        for i in 6:
                var ft := float(i) / 6.0
                var fa := 0.030 + 0.075 * ft
                draw_rect(Rect2(-600.0 - scroll.x, base_y - 380.0 + ft * 300.0, _room_width * 0.5 + 2400.0, 52.0),
                        Color(_fog.r, _fog.g, _fog.b, fa))
        # drifting fog bank: a slow breathing layer between the mid plane and
        # the play floor — depth you can feel when the camera moves
        for b in 3:
                var drift := sin(tnow * (0.05 + 0.03 * float(b)) + float(b) * 2.1) * 90.0
                var by := base_y + 18.0 + float(b) * 26.0
                var bx := -700.0 - scroll.x * 0.82 + drift
                while bx < _room_width * 0.5 - scroll.x + 700.0:
                        draw_rect(Rect2(bx, by, 320.0, 22.0 + 8.0 * float(b)),
                                Color(_fog.r, _fog.g, _fog.b, 0.035 - 0.008 * float(b)))
                        bx += 390.0
        # the plane melts into the air above the walkway — no hard bottom edge
        var fade_h := 150.0
        for i in 5:
                var t2 := float(i) / 5.0
                var a := (1.0 - t2) * 0.40
                draw_rect(Rect2(-600.0 - scroll.x, base_y - 4.0 + t2 * fade_h * 0.2, _room_width * 0.5 + 2400.0, fade_h / 5.0 + 4.0), Color(_fog.r, _fog.g, _fog.b, a))
        # a soft occlusion band right at the play-floor's back edge — the far
        # plane sits BEHIND the walkway, never on the same line as the actors
        for i in 4:
                var bt := float(i) / 4.0
                draw_rect(Rect2(-600.0 - scroll.x, base_y + 14.0 + bt * 26.0, _room_width * 0.5 + 2400.0, 10.0),
                        Color(_fog.r, _fog.g, _fog.b, 0.10 * (1.0 - bt * 0.6)))

func _poly(pts: PackedVector2Array, col: Color) -> void:
        ## Distant masses are out of focus: two offset ghost copies at partial
        ## alpha soften every edge — the far plane stops being cut paper.
        var ghost := Color(col.r, col.g, col.b, col.a * 0.38)
        var off := PackedVector2Array()
        off.resize(pts.size())
        for i in pts.size():
                off.set(i, pts[i] + Vector2(2.4, 0.6))
        draw_colored_polygon(off, ghost)
        for i in pts.size():
                off.set(i, pts[i] - Vector2(2.4, 0.6))
        draw_colored_polygon(off, ghost)
        draw_colored_polygon(pts, col)

func _mound(c: Vector2, r: float, col: Color) -> void:
        var pts := PackedVector2Array()
        for i in 10:
                var ang := PI * float(i) / 9.0
                pts.append(c + Vector2(cos(ang) * r, -sin(ang) * r * 0.42))
        pts.append(c + Vector2(-r, 2.0))
        pts.append(c + Vector2(r, 2.0))
        var ghost := Color(col.r, col.g, col.b, col.a * 0.4)
        draw_colored_polygon(PackedVector2Array([c + Vector2(-r - 2.2, 2.0), c + Vector2(r + 2.2, 2.0), c + Vector2(r + 2.2, -r * 0.1), c + Vector2(-r - 2.2, -r * 0.1)]), ghost)
        draw_colored_polygon(pts, col)

func _hline(x0: float, x1: float, y: float, col: Color) -> void:
        draw_line(Vector2(x0, y), Vector2(x1, y), col, 1.0)
