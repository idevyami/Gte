## Procession — the far life of the City of Ash. Tiny silhouettes living on
## the painted backdrop's own ground plane (the same parallax factor, the
## SAME painted street line the backdrop tiles anchor to): pilgrim lines
## with bobbing lanterns — some carrying a bier — wheeling birds around the
## spires, funeral lanterns rising, a lantern-lit funeral wagon, chapel
## censers, engine gangs swinging picks in unison.
## The city is not a painting; it is a place, and it goes about its rites
## whether the vessel watches or not.
## At higher stages the far life joins the wrongness: figures stutter, a
## lantern gutters out of phase, the bier's pall forgets itself for a frame.
class_name Procession
extends Node2D

var backdrop_key := ""
var _room := Vector2(1280, 720)
var _floor_y := 660.0
var _fog := E0.VOID
var _camera: Camera2D
var _t := 0.0

var _walkers: Array = []       # the pilgrim line(s)
var _birds: Array = []
var _lanterns: Array = []
var _wagon := {}
var _preset := {}
var _lane_mode := false        # true = the back-edge-of-floor depth row

## Per-district choreography: who walks, where, how fast, carrying what.
## y_off is relative to the painted street line (the far edge of the painted
## ground, where the buildings' feet meet it): POSITIVE y_off walks the
## painted street's near side (larger figures, closer), negative lifts the
## line above the street (galleries, ledges). scale multiplies figure height.
const PRESETS := {
        "vessels": {"walkers": [
                                {"y_off": 50.0, "count": 5, "speed": 6.0, "dir": 1, "scale": 1.2, "lantern": true},
                        ], "birds": 0, "lanterns": 3, "wagon": false},
        "city": {"walkers": [
                                {"y_off": -2.0, "count": 8, "speed": 9.0, "dir": -1, "scale": 1.05, "lantern": true},
                        ], "birds": 6, "lanterns": 6, "wagon": true},
        "undercity": {"walkers": [
                                {"y_off": 30.0, "count": 6, "speed": 7.0, "dir": 1, "scale": 1.6, "lantern": true},
                        ], "birds": 0, "lanterns": 7, "wagon": false},
        "chapel": {"walkers": [
                                {"y_off": -115.0, "count": 7, "speed": 4.0, "dir": 1, "scale": 1.35, "bier": true, "censer": true, "lantern": true},
                        ], "birds": 0, "lanterns": 2, "wagon": false},
        "archive": {"walkers": [
                                {"y_off": -100.0, "count": 2, "speed": 9.0, "dir": 1, "scale": 1.25, "lantern": true},
                        ], "birds": 0, "lanterns": 1, "wagon": false},
        "engine": {"walkers": [
                                {"y_off": -8.0, "count": 5, "speed": 13.0, "dir": -1, "scale": 1.3, "hammer": true},
                        ], "birds": 0, "lanterns": 0, "wagon": false},
        "reliquary": {"walkers": [
                                {"y_off": -115.0, "count": 6, "speed": 5.0, "dir": 1, "scale": 1.3, "bier": true, "lantern": true},
                        ], "birds": 0, "lanterns": 3, "wagon": false},
        "aftermath": {"walkers": [
                                {"y_off": -2.0, "count": 6, "speed": 5.0, "dir": -1, "scale": 1.0, "lantern": true},
                        ], "birds": 4, "lanterns": 5, "wagon": false},
}

## The LANE row: figures walking the play floor's back edge — the classic
## side-scroller depth row. Always grounded, always readable; they share
## the walkway's far side with the kneeling queues.
const LANE_PRESETS := {
        "city": [ {"count": 6, "speed": 14.0, "dir": -1, "scale": 1.65, "bier": true, "lantern": true} ],
        "undercity": [ {"count": 5, "speed": 8.0, "dir": 1, "scale": 1.5, "lantern": true} ],
        "aftermath": [ {"count": 5, "speed": 7.0, "dir": -1, "scale": 1.6, "bier": true, "lantern": true} ],
}

func setup(p_backdrop: String, room_size: Vector2, camera: Camera2D, p_floor_y: float, p_fog: Color) -> void:
        backdrop_key = p_backdrop
        _room = room_size
        _camera = camera
        _floor_y = p_floor_y if p_floor_y > 0.0 else room_size.y * 0.9
        _fog = p_fog
        z_index = -8          # between the backdrop (-10) and the midground (-5)
        _preset = PRESETS.get(p_backdrop, {})
        _seed_all()
        queue_redraw()

func setup_lane(p_backdrop: String, room_size: Vector2, camera: Camera2D, p_floor_y: float, p_fog: Color) -> void:
        ## The near depth row on the floor's back edge — in front of the
        ## midground veils, behind the near architecture and actors.
        backdrop_key = p_backdrop
        _room = room_size
        _camera = camera
        _floor_y = p_floor_y if p_floor_y > 0.0 else room_size.y * 0.9
        _fog = p_fog
        _lane_mode = true
        z_index = -2
        _walkers = []
        _birds = []
        _lanterns = []
        _wagon = {}
        var span := _room.x + 560.0
        var rng := RandomNumberGenerator.new()
        rng.seed = hash("lane:" + p_backdrop)
        for line in LANE_PRESETS.get(p_backdrop, []):
                var count: int = line.get("count", 5)
                var stride := span / float(count)
                for i in count:
                        var x0 := (float(i) + 0.5) * stride + rng.randf_range(-22.0, 22.0)
                        _walkers.append({
                                "x": fposmod(x0, span) - 280.0,
                                "line": line,
                                "i": i,
                                "ph": rng.randf() * TAU,
                                "h": rng.randf_range(13.0, 16.0) * float(line.get("scale", 1.0)),
                                "stut": rng.randf(),
                        })
        queue_redraw()

func mover_count() -> int:
        ## Everything that lives and moves on the far plane — testable.
        var n := _walkers.size() + _birds.size() + _lanterns.size()
        if not _wagon.is_empty():
                n += 1
        return n

func _seed_all() -> void:
        var rng := RandomNumberGenerator.new()
        rng.seed = hash("procession:" + backdrop_key)
        _walkers.clear()
        _birds.clear()
        _lanterns.clear()
        _wagon = {}
        var span := _room.x + 560.0
        for line in _preset.get("walkers", []):
                var count: int = line.get("count", 5)
                var dir: float = line.get("dir", 1.0)
                # distribute across the FULL room width — a tight cluster ends
                # up hidden behind one painted statue; a spread line always
                # has figures crossing the visible gaps
                var stride := span / float(count)
                for i in count:
                        var x0 := (float(i) + 0.5) * stride + rng.randf_range(-18.0, 18.0)
                        _walkers.append({
                                "x": fposmod(x0, span) - 280.0,
                                "line": line,
                                "i": i,
                                "ph": rng.randf() * TAU,
                                "h": rng.randf_range(12.0, 16.0) * float(line.get("scale", 1.0)),
                                "stut": rng.randf(),          # stutter seed (stage >= 3)
                        })
        # birds: Lissajous paths around anchors HIGH above the street — above
        # the midground rooftop silhouettes, drawn PALE (ash-wraiths) so they
        # read against the dark sky band
        for i in int(_preset.get("birds", 0)):
                _birds.append({
                        "anchor": Vector2(rng.randf_range(80.0, _room.x - 80.0),
                                        _street_line() - rng.randf_range(380.0, 520.0)),
                        "rx": rng.randf_range(30.0, 66.0),
                        "ry": rng.randf_range(12.0, 24.0),
                        "fa": rng.randf_range(0.10, 0.22),
                        "fb": rng.randf_range(0.16, 0.30),
                        "ph": rng.randf() * TAU,
                        "flap": rng.randf_range(5.0, 8.0),
                })
        # funeral lanterns: rise from the district floor, sway, fade, respawn
        for i in int(_preset.get("lanterns", 0)):
                _lanterns.append({
                        "x": rng.randf_range(0.0, _room.x),
                        "prog": rng.randf(),
                        "speed": rng.randf_range(0.010, 0.020),
                        "sway": rng.randf_range(3.0, 8.0),
                        "ph": rng.randf() * TAU,
                        "r": rng.randf_range(1.8, 2.7),
                })
        if _preset.get("wagon", false):
                _wagon = {"x": rng.randf_range(0.0, _room.x), "dir": 1.0 if rng.randf() < 0.5 else -1.0,
                                "speed": rng.randf_range(4.0, 6.0)}

func _street_line() -> float:
        ## The painted street of the backdrop tiling — the exact line the
        ## Parallax painter anchors its tiles to (floor - lift - camera lag):
        ## parallax ground_y = floor - 42 - scroll.y*0.25, tile ground sits a
        ## further scroll.y*0.15 above that. Same plane, same street.
        var lag := 0.0
        if _camera:
                lag = _camera.global_position.y * 0.25 * 0.40
        return _floor_y - 42.0 - lag

func _process(delta: float) -> void:
        _t += delta
        var stage: int = GameState.stage
        var span := _room.x + 560.0
        for w in _walkers:
                var line: Dictionary = w["line"]
                # the far life stutters when the record frays (S3+): a figure
                # hiccups backwards a few px, flickering — never the whole line
                if stage >= 3 and float(w["stut"]) > 0.72:
                        if fmod(_t * 0.5 + float(w["ph"]), 3.0) < 0.09:
                                w["x"] -= float(line.get("dir", 1.0)) * 3.0
                w["x"] += float(line.get("speed", 6.0)) * float(line.get("dir", 1.0)) * delta
                w["x"] = fposmod(float(w["x"]) + 280.0, span) - 280.0
        for l in _lanterns:
                l["prog"] += float(l["speed"]) * delta
                if float(l["prog"]) > 1.0:
                        l["prog"] = 0.0
                        l["x"] = randf() * _room.x
        if not _wagon.is_empty():
                _wagon["x"] = fposmod(float(_wagon["x"]) + float(_wagon["speed"]) * float(_wagon["dir"]) * delta + 280.0, span) - 280.0
        queue_redraw()

func _draw() -> void:
        if _preset.is_empty() and not _lane_mode:
                return
        var scroll := Vector2.ZERO
        if _camera and not _lane_mode:
                scroll = _camera.global_position * 0.25
        var ground := _floor_y - 6.0 if _lane_mode else _street_line()
        var warm := Color(0.98, 0.74, 0.36)
        var stage: int = GameState.stage
        # --- the walking lines. Near lines (large scale) keep dark bodies —
        #     close pedestrians are figures; far lines fade into the air.
        #     The lane row walks the floor's back edge: world-fixed, slightly
        #     fog-tinted, BEHIND the actors but clearly present.
        for w in _walkers:
                var line: Dictionary = w["line"]
                var wscale: float = float(line.get("scale", 1.0))
                var fog_k: float
                if _lane_mode:
                        fog_k = 0.24
                else:
                        fog_k = clampf(0.46 - (wscale - 1.0) * 0.26, 0.10, 0.46)
                var body_col := Color(E0.CHARCOAL.r, E0.CHARCOAL.g, E0.CHARCOAL.b, 1.0).lerp(
                        Color(_fog.r, _fog.g, _fog.b), fog_k).darkened(0.10)
                var px: float = float(w["x"]) - scroll.x
                var py: float
                if _lane_mode:
                        py = ground + float(line.get("y_off", 0.0))
                else:
                        py = ground + float(line.get("y_off", -8.0))
                var dir: float = line.get("dir", 1.0)
                var hpx: float = w["h"]
                var alpha := 0.92
                # S3+: the distant crowd flickers with the record
                if stage >= 3 and float(w["stut"]) > 0.72 and fmod(_t * 7.0 + float(w["ph"]), 4.0) < 0.3:
                        alpha = 0.4
                var bob := sin(_t * float(line.get("speed", 6.0)) * 0.9 + float(w["ph"])) * 1.2
                _draw_pilgrim(Vector2(px, py + bob), hpx, dir, body_col, alpha)
                if line.get("lantern", false):
                        _draw_far_light(Vector2(px - dir * hpx * 0.36, py + bob - hpx * 0.55),
                                1.5 * float(line.get("scale", 1.0)), warm,
                                0.95 * alpha * (0.85 + 0.15 * sin(_t * 9.0 + float(w["ph"]))))
                if line.get("hammer", false):
                        _draw_pick(Vector2(px, py + bob), hpx, dir, float(w["ph"]), body_col, alpha)
                if line.get("bier", false) and int(w["i"]) % 4 == 2:
                        _draw_bier(Vector2(px, py + bob), hpx, dir, body_col, alpha, stage)
                if line.get("censer", false) and int(w["i"]) == 0:
                        _draw_far_censer(Vector2(px - dir * hpx * 0.42, py + bob - hpx * 0.5),
                                dir, warm, alpha)
        # --- wheeling birds: pale ash-wraiths against the dark sky band.
        #     Each carries a short fading wake — the flight path itself reads,
        #     even in a still frame.
        for b in _birds:
                var a: Vector2 = b["anchor"]
                var fa: float = b["fa"]
                var fb: float = b["fb"]
                var ph: float = b["ph"]
                var rx: float = b["rx"]
                var ry: float = b["ry"]
                var p := Vector2(a.x + sin(_t * fa + ph) * rx,
                                a.y + sin(_t * fb + ph * 1.7) * ry) - scroll
                var flap := sin(_t * float(b["flap"]) + ph)
                var wing := 7.4 + 2.6 * flap
                var col := Color(E0.BONE.r, E0.BONE.g, E0.BONE.b, 0.78)
                draw_line(p + Vector2(-wing, -wing * 0.35), p, col, 1.8)
                draw_line(p, p + Vector2(wing, -wing * 0.35), col, 1.8)
                # flight wake: fading streak along the recent path
                for k in 3:
                        var dt := 0.22 * float(k + 1)
                        var q := Vector2(a.x + sin((_t - dt) * fa + ph) * rx,
                                        a.y + sin((_t - dt) * fb + ph * 1.7) * ry) - scroll
                        var q2 := Vector2(a.x + sin((_t - dt - 0.11) * fa + ph) * rx,
                                        a.y + sin((_t - dt - 0.11) * fb + ph * 1.7) * ry) - scroll
                        draw_line(q, q2, Color(E0.BONE.r, E0.BONE.g, E0.BONE.b, 0.22 - 0.06 * k), 1.2)
        # --- rising funeral lanterns
        for l in _lanterns:
                var prog: float = l["prog"]
                var env := sin(PI * clampf(prog, 0.0, 1.0))
                var p := Vector2(float(l["x"]) + sin(_t * 0.7 + float(l["ph"])) * float(l["sway"]),
                                ground + 4.0 - prog * 250.0) - Vector2(scroll.x, scroll.y * 0.6)
                _draw_far_light(p, float(l["r"]), warm, 0.95 * env)
        # --- the funeral wagon (city only): rolls the street's near side
        if not _wagon.is_empty():
                var bx: float = _wagon["x"] - scroll.x
                var by := ground + 34.0
                var bdir: float = _wagon["dir"]
                var wagon_col := Color(E0.CHARCOAL.r, E0.CHARCOAL.g, E0.CHARCOAL.b, 1.0).lerp(
                        Color(_fog.r, _fog.g, _fog.b), 0.16).darkened(0.10)
                var wc := Color(wagon_col.r, wagon_col.g, wagon_col.b, 0.95)
                # bed + draped pall
                draw_rect(Rect2(bx - 15.0, by - 9.0, 30.0, 5.0), wc)
                var pall := PackedVector2Array([
                        Vector2(bx - 14.0, by - 9.0), Vector2(bx + 14.0, by - 9.0),
                        Vector2(bx + 11.0, by - 3.5), Vector2(bx - 11.0, by - 3.5)])
                draw_colored_polygon(pall, Color(wc.r, wc.g, wc.b, 0.8))
                # wheels
                draw_arc(Vector2(bx - 9.0, by - 1.0), 3.0, 0.0, TAU, 8, wc, 1.4)
                draw_arc(Vector2(bx + 9.0, by - 1.0), 3.0, 0.0, TAU, 8, wc, 1.4)
                # the hooded puller and the pole
                draw_line(Vector2(bx + bdir * 15.0, by - 6.0), Vector2(bx + bdir * 26.0, by - 4.0), wc, 1.4)
                _draw_pilgrim(Vector2(bx + bdir * 28.0, by), 15.0, bdir, wagon_col, 0.92)
                _draw_far_light(Vector2(bx - bdir * 15.0, by - 11.0), 1.9, warm, 0.95)
                _draw_far_light(Vector2(bx + bdir * 13.0, by - 11.0), 1.5, warm, 0.8)

func _draw_pilgrim(p: Vector2, h: float, dir: float, col: Color, alpha: float) -> void:
        ## A far-plane hooded figure: tapered robe + hood bump + a shuffle
        ## suggestion (the robe hem leans into the walk direction).
        var c := Color(col.r, col.g, col.b, alpha)
        var lean := dir * h * 0.10
        var body := PackedVector2Array([
                p + Vector2(-h * 0.17, 0.0), p + Vector2(h * 0.17, 0.0),
                p + Vector2(h * 0.14 + lean * 0.4, -h * 0.72),
                p + Vector2(-h * 0.14 + lean * 0.4, -h * 0.72)])
        draw_colored_polygon(body, c)
        draw_circle(p + Vector2(lean * 0.5, -h * 0.82), h * 0.16, c)
        # the hem shuffles: two alternating nubs at the robe base
        var sh := 1.0 if sin(_t * 8.0 + p.x * 0.7) > 0.0 else -1.0
        draw_line(p + Vector2(-h * 0.10, 0.0), p + Vector2(-h * 0.10 + dir * sh * 1.3, -1.8), c, 1.2)

func _draw_bier(p: Vector2, h: float, dir: float, col: Color, alpha: float, stage: int) -> void:
        ## The funeral pall: a draped load carried between bearers. At S5+
        ## the pall intermittently forgets to be there (a one-frame absence).
        if stage >= 5 and fmod(_t * 2.3, 5.0) < 0.12:
                return
        var c := Color(col.r, col.g, col.b, alpha * 0.95)
        var y := p.y - h * 0.55
        draw_line(p + Vector2(-h * 0.6, y), p + Vector2(h * 0.6, y), c, 1.6)
        var pall := PackedVector2Array([
                p + Vector2(-h * 0.55, y), p + Vector2(h * 0.55, y),
                p + Vector2(h * 0.46, y + h * 0.17), p + Vector2(-h * 0.46, y + h * 0.17)])
        draw_colored_polygon(pall, Color(c.r, c.g, c.b, alpha * 0.78))
        # rope down to the bearer hands
        draw_line(p + Vector2(-h * 0.44, y), p + Vector2(-h * 0.30, y + h * 0.11), Color(c.r, c.g, c.b, alpha * 0.55), 0.9)

func _draw_pick(p: Vector2, h: float, dir: float, ph: float, col: Color, alpha: float) -> void:
        ## Engine gang: a tool swinging in the work rhythm, spark at contact.
        var period := 1.9
        var k := fmod(_t / period + ph * 0.11, 1.0)
        var e := k * k * (3.0 - 2.0 * k)          # smoothstep: windup -> strike
        var ang := lerpf(-0.9, 1.0, e)
        var hand := p + Vector2(dir * h * 0.12, -h * 0.55)
        var tool_len := h * 0.62
        var tip := hand + Vector2(sin(ang), -cos(ang)) * tool_len * dir
        draw_line(hand, tip, Color(col.r, col.g, col.b, alpha * 0.95), 1.3)
        # spark flash the instant the pick lands
        if k > 0.965:
                draw_circle(tip, 2.0, Color(0.97, 0.84, 0.55, alpha * (1.0 - (k - 0.965) / 0.035)))
                draw_circle(tip, 4.0, Color(0.97, 0.84, 0.55, alpha * 0.3 * (1.0 - (k - 0.965) / 0.035)))

func _draw_far_censer(p: Vector2, dir: float, warm: Color, alpha: float) -> void:
        ## The chapel line leads with a swinging censer on a chain.
        var ang := sin(_t * 2.1) * 0.55
        var chain_end := p + Vector2(sin(ang) * 7.0, cos(ang) * 7.0)
        draw_line(p, chain_end, Color(warm.r, warm.g, warm.b, alpha * 0.5), 1.0)
        _draw_far_light(chain_end, 2.0, warm, 1.0 * alpha)
        # a thin smoke thread rising from the censer
        for k in 3:
                var kk := float(k) / 3.0
                var sm := p + Vector2(sin(_t * 1.3 + kk * 2.0) * (1.5 + kk * 3.0), -kk * 15.0 - 5.0)
                draw_circle(sm, 1.0 - kk * 0.2, Color(warm.r, warm.g, warm.b, alpha * 0.16 * (1.0 - kk)))

func _draw_far_light(p: Vector2, r: float, col: Color, alpha: float) -> void:
        ## A far lantern: hot core + one soft halo. The warm/cool temperature
        ## gap is what makes it readable against a grey city — brightness
        ## alone dies in the fog.
        if alpha <= 0.02:
                return
        draw_circle(p, r * 3.8, Color(col.r, col.g, col.b, alpha * 0.17))
        draw_circle(p, r * 2.2, Color(col.r, col.g, col.b, alpha * 0.32))
        draw_circle(p, r, Color(1.0, 0.93, 0.74, alpha))
