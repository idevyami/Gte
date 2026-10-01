## WorldMap — THE CITY OF ASH, in section. The nine districts as strata of
## the same idea at different depths: the iron womb at the bottom, the open
## sky at the top, everything administrative in between. Visited strata are
## lit and named; unmeasured ones stay dark. The route is a gold thread;
## the vessel is a pulsing mark wherever it currently stands.
class_name WorldMap
extends Control

signal closed

var _t := 0.0
var _districts: Array = [
        # key, act numeral, name, depth label
        ["act9",  "IX",  "THE SURFACE",              "SURFACE"],
        ["act8",  "VIII", "THE RELIQUARY",           "SUBLEVEL I"],
        ["act7",  "VII", "THE ENGINE SANCTUM",       "SUBLEVEL II"],
        ["act6",  "VI",  "THE WATCHING",             "SUBLEVEL III"],
        ["act5",  "V",   "THE CHAPEL OF THE PALE SAINT", "SUBLEVEL IV"],
        ["act4",  "IV",  "THE CONTRADICTION",        "SUBLEVEL V"],
        ["act3",  "III", "THE CITY OF ASH",          "SUBLEVEL VI"],
        ["act2",  "II",  "THE FIRST DOOR",           "SUBLEVEL VIII"],
        ["act1",  "I",   "THE VESSEL CHAMBER",       "SUBLEVEL IX"],
]

func _ready() -> void:
        set_anchors_preset(Control.PRESET_FULL_RECT)
        mouse_filter = Control.MOUSE_FILTER_IGNORE
        process_mode = Node.PROCESS_MODE_ALWAYS
        z_index = 62
        visible = false

func open() -> void:
        _t = 0.0
        visible = true
        GameState.map_open = true
        FX.push_reading()
        AudioManager.play_sfx("sfx_terminal", -8.0)

func close_map() -> void:
        visible = false
        GameState.map_open = false
        FX.pop_reading()
        closed.emit()

func _process(delta: float) -> void:
        if visible:
                _t = minf(_t + delta * 2.6, 1.0)
                queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
        if not visible:
                return
        if event.is_action_pressed("pause") or event.is_action_pressed("interact") or event.is_action_pressed("observe"):
                accept_event()
                close_map()

# ------------------------------------------------------------------ layout
func _stratum_rects(vp: Vector2) -> Array:
        ## Strata stacked bottom-deepest; returns [{rect, data, idx}].
        var margin_x := maxf(120.0, (vp.x - 640.0) * 0.5)
        var top := 92.0
        var bottom := vp.y - 88.0
        var n := _districts.size()
        var gap := 8.0
        var h := (bottom - top - gap * (n - 1)) / float(n)
        var out: Array = []
        for i in n:
                var r := Rect2(margin_x, top + i * (h + gap), vp.x - margin_x * 2.0, h)
                out.append({"rect": r, "data": _districts[i], "idx": i})
        return out

func _draw() -> void:
        if not visible:
                return
        var vp := get_viewport_rect().size
        var ease := 1.0 - pow(1.0 - _t, 3.0)
        # the void behind the city
        draw_rect(Rect2(Vector2.ZERO, vp), Color(0.03, 0.028, 0.032, 0.94 * ease))

        # ---- header
        var hx := vp.x * 0.5
        draw_string(E0.serif, Vector2(hx, 56.0), "THE CITY OF ASH", HORIZONTAL_ALIGNMENT_CENTER, -1, 30,
                Color(E0.BONE.r, E0.BONE.g, E0.BONE.b, ease))
        draw_string(E0.mono, Vector2(hx, 76.0), "IN SECTION — NINE STRATA, ONE DESIGN", HORIZONTAL_ALIGNMENT_CENTER, -1, 10,
                Color(E0.DIM.r, E0.DIM.g, E0.DIM.b, 0.9 * ease))
        # gold hairline under the title
        draw_line(Vector2(hx - 170.0, 86.0), Vector2(hx + 170.0, 86.0), Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.5 * ease), 1.0)

        var strata := _stratum_rects(vp)
        var route_pts := PackedVector2Array()

        for s in strata:
                var r: Rect2 = s["rect"]
                var d: Array = s["data"]
                var idx: int = s["idx"]
                var key := String(d[0])
                var visited: bool = GameState.visited_rooms.has(key)
                var current: bool = GameState.current_room == key
                var reveal := clampf(ease * 1.5 - float(idx) * 0.08, 0.0, 1.0)

                # ---- the stratum body
                var body_col := Color(0.085, 0.08, 0.075, 0.9 * reveal)
                if visited:
                        body_col = Color(0.11, 0.1, 0.09, 0.94 * reveal)
                draw_rect(r, body_col)
                # masonry texture: seed-stable course lines
                _stratum_texture(r, hash(key), visited, reveal)
                # the district silhouette: a unique skyline per stratum
                _stratum_skyline(r, key, visited, reveal, ease)

                # ---- borders
                draw_rect(r, Color(E0.DIRTY_STONE.r, E0.DIRTY_STONE.g, E0.DIRTY_STONE.b, (0.5 if visited else 0.3) * reveal), false, 1.5)

                # ---- labels (visited: lit; unvisited: withheld)
                var lx := r.position.x + 20.0
                var ly := r.position.y + r.size.y * 0.5
                if visited:
                        draw_string(E0.serif, Vector2(lx, ly - 4.0), "ACT " + String(d[1]) + " — " + String(d[2]),
                                HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(E0.BONE.r, E0.BONE.g, E0.BONE.b, 0.95 * reveal))
                        draw_string(E0.mono, Vector2(lx, ly + 14.0), String(d[3]) + "  ·  MEASURED",
                                HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(E0.DIM.r, E0.DIM.g, E0.DIM.b, 0.95 * reveal))
                else:
                        draw_string(E0.mono, Vector2(lx, ly - 4.0), "ACT " + String(d[1]) + " — " + "NOT YET MEASURED",
                                HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.8 * reveal))

                # ---- current position: the vessel mark
                if current:
                        var mx := r.position.x + r.size.x - 44.0
                        var my := r.position.y + r.size.y * 0.5 - 6.0
                        var pulse := 0.55 + 0.45 * sin(Time.get_ticks_msec() * 0.004)
                        draw_circle(Vector2(mx, my), 3.2, Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, pulse * reveal))
                        draw_arc(Vector2(mx, my), 7.5, 0, TAU, 12, Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.4 * pulse * reveal), 1.0)
                        draw_string(E0.mono, Vector2(mx - 26.0, my + 26.0), "818", HORIZONTAL_ALIGNMENT_CENTER, -1, 9,
                                Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.8 * reveal))

                # route thread passes through each visited stratum
                var thread_x := r.position.x + r.size.x * (0.5 + 0.06 * sin(float(idx) * 2.1))
                route_pts.append(Vector2(thread_x, r.position.y + r.size.y * 0.5))

        # ---- the gold route through visited strata
        var visited_pts := PackedVector2Array()
        for i in range(strata.size() - 1, -1, -1):
                var key := String((strata[i]["data"] as Array)[0])
                if GameState.visited_rooms.has(key):
                        visited_pts.append(route_pts[i])
        if visited_pts.size() >= 2:
                for i in visited_pts.size() - 1:
                        var a := (visited_pts[i] + visited_pts[i + 1]) * 0.5 + Vector2(0, 12)
                        draw_polyline(PackedVector2Array([visited_pts[i], a, visited_pts[i + 1]]),
                                Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.34 * ease), 1.2)

        # ---- depth scale on the left edge
        for s in strata:
                var d: Array = s["data"]
                var r: Rect2 = s["rect"]
                draw_string(E0.mono, Vector2(r.position.x - 14.0, r.position.y + 12.0), String(d[3]),
                        HORIZONTAL_ALIGNMENT_RIGHT, -1, 9, Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.7 * ease))

        # ---- footer
        var foot := "ESC / F — CLOSE"
        var blink := 0.5 + 0.3 * sin(Time.get_ticks_msec() * 0.004)
        draw_string(E0.mono, Vector2(vp.x * 0.5, vp.y - 40.0), foot, HORIZONTAL_ALIGNMENT_CENTER, -1, 11,
                Color(E0.DIM.r, E0.DIM.g, E0.DIM.b, blink))
        var visited_n := 0
        for d in _districts:
                if GameState.visited_rooms.has(String(d[0])):
                        visited_n += 1
        draw_string(E0.mono, Vector2(vp.x * 0.5, vp.y - 58.0),
                "STRATA MEASURED: %d / %d  ·  INSCRIPTIONS READ: %d" % [visited_n, _districts.size(), GameState.stats.get("texts", 0)],
                HORIZONTAL_ALIGNMENT_CENTER, -1, 11, Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.85))

# ------------------------------------------------------------------ strata art
func _stratum_texture(r: Rect2, seed_hash: int, visited: bool, reveal: float) -> void:
        ## Course lines + subtle wear, per-stratum stable.
        var rng := RandomNumberGenerator.new()
        rng.seed = seed_hash
        var line_col := Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, (0.5 if visited else 0.3) * reveal)
        var y := r.position.y + 18.0
        while y < r.position.y + r.size.y - 8.0:
                draw_line(Vector2(r.position.x + 6.0, y), Vector2(r.position.x + r.size.x - 6.0, y), line_col, 1.0)
                # a few vertical joints per course
                var joints := 2 + rng.randi() % 3
                for j in joints:
                        var jx := r.position.x + 10.0 + rng.randf() * (r.size.x - 20.0)
                        draw_line(Vector2(jx, y), Vector2(jx, y + 18.0), line_col, 1.0)
                y += 18.0

func _stratum_skyline(r: Rect2, key: String, visited: bool, reveal: float, ease: float) -> void:
        ## A district silhouette along the right two-thirds of each stratum —
        ## the shape of the place, unique per district, drawn quiet so it
        ## reads as architecture, not illustration.
        var col := Color(0.16, 0.15, 0.14, (0.85 if visited else 0.45) * reveal)
        var lit := Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.5 * reveal)
        var x0 := r.position.x + r.size.x * 0.34
        var x1 := r.position.x + r.size.x - 14.0
        var base := r.position.y + r.size.y - 6.0
        var top := r.position.y + 6.0
        var rng := RandomNumberGenerator.new()
        rng.seed = hash(key) & 0x7fffffff

        match key:
                "act1":
                        # the iron womb: one great rounded vessel in a shaft
                        var cx := (x0 + x1) * 0.5
                        var w := (x1 - x0) * 0.42
                        draw_rect(Rect2(cx - w * 0.5, top + 4, w, base - top - 4), col)
                        draw_circle(Vector2(cx, top + 8 + (base - top) * 0.25), w * 0.5, col)
                        # cradle racks: thin shelves
                        for i in 3:
                                var sy := top + 16.0 + i * (base - top - 24.0) / 3.0
                                draw_line(Vector2(cx - w * 0.36, sy), Vector2(cx + w * 0.36, sy), Color(col.r, col.g, col.b, 0.7), 2.0)
                "act2":
                        # the first door: a monumental portal in a flat wall
                        var dw := 46.0
                        var cx := (x0 + x1) * 0.5
                        draw_rect(Rect2(x0, top + 10, x1 - x0, base - top - 10), Color(col.r, col.g, col.b, 0.55))
                        draw_rect(Rect2(cx - dw * 0.5, base - (base - top) * 0.62, dw, (base - top) * 0.62), Color(0.05, 0.05, 0.06, reveal))
                        # the arch of the portal
                        draw_arc(Vector2(cx, base - (base - top) * 0.62), dw * 0.5, PI, TAU, 10, col, 6.0)
                        if visited:
                                draw_circle(Vector2(cx, base - 8.0), 2.0, lit)
                "act3":
                        # the city: packed rooftops under falling ash
                        var x := x0
                        while x < x1 - 20.0:
                                var bw := 26.0 + rng.randf() * 34.0
                                var bh := (base - top) * (0.3 + rng.randf() * 0.5)
                                draw_rect(Rect2(x, base - bh, minf(bw, x1 - x - 4.0), bh), col)
                                # a roof pitch
                                draw_colored_polygon(PackedVector2Array([
                                        Vector2(x - 3, base - bh), Vector2(x + bw * 0.5, base - bh - 7.0),
                                        Vector2(x + bw + 3, base - bh)]), col)
                                if visited and rng.randf() > 0.55:
                                        draw_rect(Rect2(x + bw * 0.3, base - bh * 0.55, 3.5, 4.5), lit)
                                x += bw + 8.0
                        # ashfall ticks
                        for i in 10:
                                var ax := x0 + rng.randf() * (x1 - x0)
                                var ay := top + 4.0 + rng.randf() * (base - top - 10.0)
                                draw_line(Vector2(ax, ay), Vector2(ax - 1.5, ay + 5.0), Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.22 * reveal), 1.0)
                "act4":
                        # the contradiction: census stelae in a row
                        var x := x0 + 8.0
                        while x < x1 - 16.0:
                                var sh := (base - top) * (0.35 + rng.randf() * 0.3)
                                draw_rect(Rect2(x, base - sh, 12.0, sh), col)
                                draw_circle(Vector2(x + 6.0, base - sh - 3.0), 6.0, col)
                                x += 26.0
                "act5":
                        # the chapel: a spire and a rose window
                        var cx := (x0 + x1) * 0.5
                        var bw := (x1 - x0) * 0.5
                        draw_rect(Rect2(cx - bw * 0.5, top + 18, bw, base - top - 18), col)
                        # the spire
                        draw_colored_polygon(PackedVector2Array([
                                Vector2(cx - bw * 0.14, top + 18), Vector2(cx, top),
                                Vector2(cx + bw * 0.14, top + 18)]), col)
                        # rose window
                        if visited:
                                draw_arc(Vector2(cx, top + 34.0), 7.0, 0, TAU, 12, Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.4 * reveal), 1.5)
                                draw_circle(Vector2(cx, top + 34.0), 2.2, lit)
                        # buttresses
                        for sgn in [-1.0, 1.0]:
                                draw_colored_polygon(PackedVector2Array([
                                        Vector2(cx + sgn * bw * 0.5, base), Vector2(cx + sgn * bw * 0.62, base),
                                        Vector2(cx + sgn * bw * 0.62, base - (base - top) * 0.4)]), col)
                "act6":
                        # the watching: archive shelves, dense and repeating
                        var x := x0 + 6.0
                        while x < x1 - 24.0:
                                draw_rect(Rect2(x, top + 10, 16.0, base - top - 10), col)
                                for i in 4:
                                        var sy := top + 18.0 + i * (base - top - 24.0) / 4.0
                                        draw_line(Vector2(x + 2.0, sy), Vector2(x + 14.0, sy), Color(0.1, 0.095, 0.09, reveal), 2.0)
                                x += 24.0
                "act7":
                        # the engine: a great chamber, pipes and one heart
                        var cx := (x0 + x1) * 0.5
                        for i in 3:
                                var px := x0 + 14.0 + i * (x1 - x0 - 28.0) / 2.0
                                draw_rect(Rect2(px, top + 8, 8.0, base - top - 8), col)
                                draw_circle(Vector2(px + 4.0, top + 10.0), 6.0, col)
                        # the heart: a lit core
                        if visited:
                                var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.003)
                                draw_circle(Vector2(cx, (top + base) * 0.5), 8.0, Color(E0.CRIMSON.r, E0.CRIMSON.g, E0.CRIMSON.b, (0.4 + 0.3 * pulse) * reveal))
                                draw_arc(Vector2(cx, (top + base) * 0.5), 13.0, 0, TAU, 12,
                                        Color(E0.CRIMSON.r, E0.CRIMSON.g, E0.CRIMSON.b, 0.35 * pulse * reveal), 1.2)
                "act8":
                        # the reliquary: a chained monument under a crown
                        var cx := (x0 + x1) * 0.5
                        draw_rect(Rect2(cx - 16.0, base - (base - top) * 0.7, 32.0, (base - top) * 0.7), col)
                        draw_circle(Vector2(cx, base - (base - top) * 0.7 - 8.0), 10.0, col)
                        if visited:
                                # chains: catenary strokes over the monument
                                for sgn in [-1.0, 1.0]:
                                        var cpts := PackedVector2Array()
                                        for i in 6:
                                                var t := i / 5.0
                                                cpts.append(Vector2(cx + sgn * (14.0 + t * 26.0), base - (base - top) * (0.75 - 0.18 * sin(t * PI))))
                                        draw_polyline(cpts, Color(E0.ASH.r, E0.ASH.g, E0.ASH.b, 0.8 * reveal), 1.4)
                "act9":
                        # the surface: an open horizon, no wall at all
                        var hy := top + (base - top) * 0.55
                        draw_rect(Rect2(x0, hy, x1 - x0, base - hy), col)
                        if visited:
                                # open sky: quiet ash motes rising
                                for i in 6:
                                        var ax := x0 + rng.randf() * (x1 - x0)
                                        var ay := hy - 4.0 - rng.randf() * (hy - top)
                                        draw_circle(Vector2(ax, ay), 1.0, Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.3 * reveal))
                        draw_line(Vector2(x0, hy), Vector2(x1, hy), Color(E0.DIM.r, E0.DIM.g, E0.DIM.b, 0.5 * reveal), 1.0)
