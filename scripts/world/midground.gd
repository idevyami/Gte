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
        # span the full parallax-lagged traversal (half-speed plane)
        var x := -320.0
        var end_x := _room_width * 0.5 + 1100.0
        while x < end_x:
                var w := rng.randf_range(70.0, 190.0)
                var h := rng.randf_range(120.0, 330.0)
                var kind := _pick_kind(rng)
                _structures.append({
                        "x": x, "w": w, "h": h, "kind": kind,
                        "ph": rng.randf() * TAU,
                        "lean": rng.randf_range(-0.02, 0.02),
                })
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
                        return ["ruin", "beam", "rubble"][rng.randi() % 3]
                _:
                        return ["monolith", "monolith", "arch", "block"][rng.randi() % 4]

func _process(_delta: float) -> void:
        if _camera:
                _last_cam = _camera.global_position
        queue_redraw()

func _draw() -> void:
        var scroll := Vector2(_last_cam.x * SCROLL_K, _last_cam.y * Y_K)
        var body := Color(E0.CHARCOAL.r, E0.CHARCOAL.g, E0.CHARCOAL.b, 0.62)
        body = body.lerp(Color(_fog.r, _fog.g, _fog.b), 0.35)
        var edge := Color(E0.ASH.r, E0.ASH.g, E0.ASH.b, 0.20)
        var base_y := _horizon + 6.0 - scroll.y
        for s in _structures:
                var sx: float = s["x"] - scroll.x
                var sw: float = s["w"]
                var sh: float = s["h"]
                var top := base_y - sh
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
                                var rr := sw * 0.5
                                draw_circle(Vector2(sx + rr, base_y - 14.0), rr, body)
                                draw_circle(Vector2(sx + rr * 0.6, base_y - 8.0), rr * 0.5, body)
                        _:
                                _poly([Vector2(sx, base_y), Vector2(sx, top), Vector2(sx + sw, top), Vector2(sx + sw, base_y)], body)
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
                                draw_line(prev, p, Color(body.r, body.g, body.b, 0.5), 2.0)
                        else:
                                draw_line(prev, (prev + p) * 0.5, Color(body.r, body.g, body.b, 0.34), 1.5)
                                draw_line((prev + p) * 0.5, p, Color(body.r, body.g, body.b, 0.34), 1.5)
                        prev = p
        # the plane melts into the air above the walkway — no hard bottom edge
        var fade_h := 150.0
        for i in 5:
                var t := float(i) / 5.0
                var a := (1.0 - t) * 0.30
                draw_rect(Rect2(-600.0 - scroll.x, base_y - 4.0 + t * fade_h * 0.2, _room_width * 0.5 + 2400.0, fade_h / 5.0 + 4.0), Color(_fog.r, _fog.g, _fog.b, a))

func _poly(pts: PackedVector2Array, col: Color) -> void:
        draw_colored_polygon(pts, col)

func _hline(x0: float, x1: float, y: float, col: Color) -> void:
        draw_line(Vector2(x0, y), Vector2(x1, y), col, 1.0)
