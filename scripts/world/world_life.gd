## WorldLife — THE WORLD RESPONDS. The near-plane life that reacts to the
## vessel's passage (the WB-8 motion law): moths orbiting every flame that
## SCATTER when the player runs close and resettle when the air stills;
## ash-vermin scuttling the floor's back edge that FLEE a approaching body
## and vanish into the grates; ripple rings where boots land in the
## undercity's weep spots. Nothing here is gameplay — all of it is the city
## noticing you.
class_name WorldLife
extends Node2D

var key := ""
var district := ""
var room_size := Vector2(1280, 720)
var floor_y := 660.0
var _wake: Wake = null

var _player: Node2D = null
var _moths: Array = []          # per-flame orbiters
var _scuttlers: Array = []      # back-edge vermin
var _ripples: Array = []        # expanding step rings
var _droplets: Array = []       # splash flecks
var _damp: Array = []           # weep spots {x,y,rx}
var _step_x := -99999.0         # last step position (step detection)
var _t := 0.0

const SCUTTLER_DISTRICTS := ["undercity", "city", "archive", "aftermath", "vessels"]

# ------------------------------------------------------------------ thinning
# (THE WORLD THINS — life flees first; pure statics, smoke-pinned)

const MOTH_LEAVE_FLOOR := 0.25      # no moth leaves before this thinning
const MOTH_LEAVE_CEIL := 0.70        # by this thinning the flames stand alone

static func moth_leave_floor() -> float:
        return MOTH_LEAVE_FLOOR

static func moth_leave_ceil() -> float:
        return MOTH_LEAVE_CEIL

static func flee_radius(th: float) -> float:
        ## The vermin's nerve shortens as reality thins: the vessel is
        ## felt from further and further away (150 → 280 px).
        return 150.0 + 130.0 * clampf(th, 0.0, 1.0)

static func flee_speed(th: float) -> float:
        ## And the flight itself is faster (250 → 375 px/s).
        return 250.0 * (1.0 + 0.50 * clampf(th, 0.0, 1.0))

func set_player(p: Node2D) -> void:
        ## Called after spawn — the world needs a body to respond to.
        _player = p

func set_wake(w: Wake) -> void:
        ## THE ARRIVAL (WB-11): the near-plane life wakes with the air —
        ## moths and vermin condense into presence as the room does.
        _wake = w

func _wake_a() -> float:
        if _wake == null or _wake.done():
                return 1.0
        return _wake.air_alpha()

func setup(p_key: String, p_district: String, p_room_size: Vector2, p_lights: Array,
                p_player: Node2D, p_damp: Array, p_floor_y: float) -> void:
        key = p_key
        district = p_district
        room_size = p_room_size
        _player = p_player
        _damp = p_damp
        floor_y = p_floor_y
        var rng := RandomNumberGenerator.new()
        rng.seed = hash("worldlife:" + p_key)
        # --- moths: every flame that lives gets its orbiters (2-4, tuned by
        #     flicker strength — a busy fire feeds more wings)
        _moths.clear()
        for l in p_lights:
                var flicker: float = float(l.get("flicker", 0.0))
                if flicker < 0.15:
                        continue        # machine veins draw no moths
                var pos: Vector2 = l["pos"]
                var n := 2 + (rng.randi() % 3)
                for i in n:
                        # THE WORLD THINS: each moth carries its own nerve —
                        # the thinning at which IT gives up and goes. The
                        # departure is a WAVE (staggered thresholds), never
                        # a pop; and when the world re-asserts itself the
                        # moths RETURN to their flames.
                        var away := Vector2(1.0 if pos.x > room_size.x * 0.5 else -1.0, -0.85).normalized()
                        _moths.append({
                                "home": pos,
                                "rx": rng.randf_range(9.0, 22.0),
                                "ry": rng.randf_range(5.0, 13.0),
                                "sp": rng.randf_range(1.1, 2.3) * (1.0 if rng.randf() < 0.5 else -1.0),
                                "sp2": rng.randf_range(0.7, 1.7) * (1.0 if rng.randf() < 0.5 else -1.0),
                                "ph": rng.randf() * TAU,
                                "flap": rng.randf_range(11.0, 19.0),
                                "burst": Vector2.ZERO,
                                "warm": 0.85 + rng.randf() * 0.3,
                                "leave_th": MOTH_LEAVE_FLOOR + rng.randf() * (MOTH_LEAVE_CEIL - MOTH_LEAVE_FLOOR),
                                "alpha": 1.0,
                                "mstate": "orbit",   # orbit | leaving | returning
                                "away": away,
                        })
        # --- scuttlers: the vermin of the strata (only where vermin live)
        _scuttlers.clear()
        if SCUTTLER_DISTRICTS.has(p_district):
                var n2 := 2 + (rng.randi() % 2)
                for i in n2:
                        _scuttlers.append(_new_scuttler(rng, true))
        _ripples.clear()
        _droplets.clear()
        z_index = 0
        set_process(true)

func _new_scuttler(rng: RandomNumberGenerator, anywhere: bool) -> Dictionary:
        var x := rng.randf_range(60.0, room_size.x - 60.0)
        if not anywhere and _player != null:
                # respawn far from the player — the city refills its edges
                for tries in 6:
                        x = rng.randf_range(60.0, room_size.x - 60.0)
                        if absf(x - _player.global_position.x) > 320.0:
                                break
        return {
                "x": x, "y": floor_y + 4.0,
                "dir": 1 if rng.randf() < 0.5 else -1.0,
                "speed": rng.randf_range(24.0, 54.0),
                "ph": rng.randf() * TAU,
                "state": "patrol",       # patrol | flee | gone
                "timer": 0.0,
                "respawn": 0.0,
        }

func _process(delta: float) -> void:
        _t += delta
        var ppos := Vector2(_step_x, floor_y)
        var pv := Vector2.ZERO
        var grounded := false
        if _player != null and is_instance_valid(_player):
                ppos = _player.global_position
                pv = _player.velocity
                grounded = _player.is_on_floor()
        # --- moths: orbit, scatter from the passing body, resettle —
        #     and LEAVE FIRST when the world thins (the smallest life is
        #     the most honest barometer of reality)
        var th := GameState.thinning()
        for m in _moths:
                var home: Vector2 = m["home"]
                var ms := String(m["mstate"])
                if ms == "orbit":
                        if th > float(m["leave_th"]):
                                # past this moth's nerve: it goes, up and out
                                m["mstate"] = "leaving"
                        elif ppos.distance_to(home) < 100.0:
                                # the air moves: burst away from the body
                                var away2: Vector2 = (Vector2(home.x, home.y - 6.0) - ppos + Vector2(0.001, 0.001)).normalized()
                                m["burst"] = (m["burst"] as Vector2).lerp(away2 * 52.0, 1.0 - exp(-9.0 * delta))
                        else:
                                # the air stills: resettle onto the orbit
                                m["burst"] = (m["burst"] as Vector2).lerp(Vector2.ZERO, 1.0 - exp(-1.6 * delta))
                if String(m["mstate"]) == "leaving":
                        # it flies its one decisive exit, fading as it goes
                        m["burst"] = (m["burst"] as Vector2).lerp((m["away"] as Vector2) * 78.0, 1.0 - exp(-2.5 * delta))
                        m["alpha"] = maxf(0.0, float(m["alpha"]) - delta / 1.1)
                        if th < float(m["leave_th"]) - 0.08:
                                m["mstate"] = "returning"   # the world re-asserts
                elif String(m["mstate"]) == "returning":
                        m["burst"] = (m["burst"] as Vector2).lerp(Vector2.ZERO, 1.0 - exp(-1.6 * delta))
                        m["alpha"] = minf(1.0, float(m["alpha"]) + delta / 1.6)
                        if float(m["alpha"]) >= 1.0:
                                m["mstate"] = "orbit"
                        elif th > float(m["leave_th"]):
                                m["mstate"] = "leaving"     # thinned again mid-return
        # --- scuttlers: patrol the back edge, flee the vessel, vanish, return
        var rng := RandomNumberGenerator.new()
        rng.seed = hash("wl:" + key)
        for s in _scuttlers:
                match String(s["state"]):
                        "patrol":
                                s["x"] = float(s["x"]) + float(s["dir"]) * float(s["speed"]) * delta
                                if float(s["x"]) < 40.0 or float(s["x"]) > room_size.x - 40.0:
                                        s["dir"] = -float(s["dir"])
                                        s["x"] = clampf(float(s["x"]), 40.0, room_size.x - 40.0)
                                # a passing body inside the (thinned) nerve radius = flight
                                if absf(ppos.x - float(s["x"])) < flee_radius(th) and absf(ppos.y - floor_y) < 90.0:
                                        s["state"] = "flee"
                                        s["dir"] = 1.0 if ppos.x < float(s["x"]) else -1.0
                                        s["timer"] = rng.randf_range(1.1, 1.9)
                        "flee":
                                s["x"] = float(s["x"]) + float(s["dir"]) * flee_speed(th) * delta
                                s["timer"] = float(s["timer"]) - delta
                                if float(s["timer"]) <= 0.0 or float(s["x"]) < 20.0 or float(s["x"]) > room_size.x - 20.0:
                                        s["state"] = "gone"
                                        s["respawn"] = rng.randf_range(7.0, 15.0)
                        "gone":
                                s["respawn"] = float(s["respawn"]) - delta
                                if float(s["respawn"]) <= 0.0:
                                        var ns := _new_scuttler(rng, false)
                                        s["x"] = ns["x"]
                                        s["dir"] = ns["dir"]
                                        s["speed"] = ns["speed"]
                                        s["state"] = "patrol"
        # --- step detection: every ~24px of grounded travel is a footfall
        if grounded and absf(pv.x) > 30.0:
                if _step_x < -90000.0:
                        _step_x = ppos.x
                elif absf(ppos.x - _step_x) >= 24.0:
                        _step_x = ppos.x
                        _footfall(ppos)
        else:
                _step_x = ppos.x if grounded else _step_x
        # --- ripples live briefly
        for r in _ripples:
                r["t"] = float(r["t"]) + delta * 1.4
        _ripples = _ripples.filter(func(r): return float(r["t"]) < 1.0)
        for d in _droplets:
                d["pos"] = (d["pos"] as Vector2) + (d["v"] as Vector2) * delta
                d["v"] = (d["v"] as Vector2) + Vector2(0, 260) * delta
                d["t"] = float(d["t"]) + delta
        _droplets = _droplets.filter(func(d): return float(d["t"]) < 0.5)
        queue_redraw()

func _footfall(pos: Vector2) -> void:
        ## A boot lands. In the weeping strata it lands in water.
        for spot in _damp:
                var sx: float = spot["x"]
                var sy: float = spot["y"]
                var srx: float = spot["rx"]
                if absf(pos.x - sx) < srx and absf(pos.y - sy) < 30.0:
                        _ripples.append({"x": sx + (pos.x - sx) * 0.4, "y": sy, "t": 0.0})
                        if _droplets.size() < 24:
                                for i in 3:
                                        var ang := -PI * (0.35 + 0.22 * float(i))
                                        _droplets.append({
                                                "pos": Vector2(pos.x, sy - 1.0),
                                                "v": Vector2(cos(ang) * (18.0 + 12.0 * float(i)), sin(ang) * 46.0),
                                                "t": 0.0,
                                        })
                        break

func _draw() -> void:
        var wa := _wake_a()
        # --- moths: pale wings around every flame
        for m in _moths:
                var malpha: float = float(m["alpha"])
                if malpha <= 0.012:
                        continue            # gone with the thinning — undrawn
                var home: Vector2 = m["home"]
                var rx: float = m["rx"]
                var ry: float = m["ry"]
                var sp: float = m["sp"]
                var sp2: float = m["sp2"]
                var ph: float = m["ph"]
                var burst: Vector2 = m["burst"]
                var p := home + Vector2(
                        cos(_t * sp + ph) * rx + sin(_t * sp2 + ph * 1.7) * rx * 0.3,
                        sin(_t * sp2 + ph) * ry) + burst
                var leaving := String(m["mstate"]) == "leaving"
                var flap := absf(sin(_t * float(m["flap"]) * (1.45 if leaving else 1.0) + ph))
                var warm: float = m["warm"]
                var col := Color(E0.PARCH.r * warm, E0.PARCH.g * warm, E0.PARCH.b * 0.95, (0.55 + 0.35 * flap) * wa * malpha)
                # two wing triangles beating around a bone body
                var wing := 1.4 + 1.5 * flap
                draw_colored_polygon(PackedVector2Array([
                        p + Vector2(-0.8, 0),
                        p + Vector2(-2.6 - wing, -1.6 - wing * 0.6),
                        p + Vector2(-1.2 - wing * 0.4, 0.8),
                ]), Color(col.r, col.g, col.b, col.a * 0.8))
                draw_colored_polygon(PackedVector2Array([
                        p + Vector2(0.8, 0),
                        p + Vector2(2.6 + wing, -1.6 - wing * 0.6),
                        p + Vector2(1.2 + wing * 0.4, 0.8),
                ]), Color(col.r, col.g, col.b, col.a * 0.8))
                draw_circle(p, 0.9, Color(E0.BONE.r, E0.BONE.g, E0.BONE.b, 0.8 * wa * malpha))
        # --- scuttlers: the vermin of the floor's back edge
        # (READABILITY LAW: a 9px body must survive a dark floor — the body
        # carries a pale dorsal highlight, bone eye-glints big enough to
        # catch, and its own contact shadow)
        for s in _scuttlers:
                if String(s["state"]) == "gone":
                        continue
                var x: float = s["x"]
                var y: float = s["y"]
                var dir: float = s["dir"]
                var ph: float = s["ph"]
                var fleeing := String(s["state"]) == "flee"
                var bob := sin(_t * (26.0 if fleeing else 15.0) + ph) * 0.5
                var cp := Vector2(x, y - 2.6 + bob)
                var SC := 1.2     # the readability scale — a touch larger than
                                  # life so the silhouette survives busy stone
                # its own soft shadow grounds it on the stones
                _ellipse_local(Vector2(x, y + 0.6), 5.4 * SC, 1.5 * SC, Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.38))
                # ASH-VERMIN (the readability law, WB-7's lesson): the city's
                # rats are PALE — creatures of the ashfall, bone-dusted, a
                # pale silhouette on dark stone. Dark-on-dark was invisible.
                var body_col := Color(E0.BONE.r * 0.62, E0.BONE.g * 0.60, E0.BONE.b * 0.54, 0.97 * wa)
                # body
                _ellipse_local(cp, 4.2 * SC, 2.0 * SC, body_col)
                # darker dorsal stripe — the fur parts along the spine
                _ellipse_local(cp + Vector2(-0.3 * dir, -0.4), 3.2 * SC, 0.7 * SC,
                        Color(E0.ASH.r * 0.9, E0.ASH.g * 0.9, E0.ASH.b * 0.95, 0.55))
                # head + crimson eyes (alive, and they READ)
                var hp2 := cp + Vector2(4.6 * dir * SC, -0.5 * SC)
                _ellipse_local(hp2, 1.8 * SC, 1.4 * SC, body_col)
                draw_circle(hp2 + Vector2(0.8 * dir, -0.6), 0.75,
                        Color(E0.BLOOD.r * 1.3, E0.BLOOD.g * 0.8, E0.BLOOD.b * 0.8, 0.95))
                draw_circle(hp2 + Vector2(-0.4 * dir, -0.7), 0.55,
                        Color(E0.BLOOD.r * 1.1, E0.BLOOD.g * 0.7, E0.BLOOD.b * 0.7, 0.7))
                # whiskers — the head feels the air ahead
                draw_line(hp2, hp2 + Vector2(2.8 * dir, -1.5),
                        Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.45), 0.5)
                draw_line(hp2, hp2 + Vector2(3.0 * dir, 0.2),
                        Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.38), 0.5)
                # legs: two alternating pairs, scuttling (dark under pale)
                var leg_spd := 30.0 if fleeing else 17.0
                for i in 2:
                        var la := sin(_t * leg_spd + ph + float(i) * PI)
                        draw_line(cp + Vector2(-2.2 + float(i) * 3.8, 1.3) * SC,
                                cp + Vector2(-2.2 + float(i) * 3.8 + la * 1.8 * dir, 3.0) * SC,
                                Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.85), 0.9)
                # tail: a long nervous curve, raised when fleeing
                var tail_up := -3.8 if fleeing else -1.5
                draw_polyline(PackedVector2Array([
                        cp + Vector2(-4.2 * dir, 0.0) * SC,
                        cp + Vector2(-7.0 * dir, tail_up * 0.6) * SC,
                        cp + Vector2(-9.6 * dir, tail_up + sin(_t * 9.0 + ph) * 0.9) * SC,
                ]), Color(E0.BONE.r * 0.5, E0.BONE.g * 0.48, E0.BONE.b * 0.44, 0.9), 1.2)
        # --- ripples: rings opening where the boot met the water
        # (VISIBILITY LAW: a 1px hairline dies on textured stone — the ring
        # carries width, a soft water-glow beneath it, and a second inner
        # ring so the EXPANSION reads, not just a circle)
        for r in _ripples:
                var t: float = r["t"]
                var rx := 4.0 + t * 36.0
                var ry := rx * 0.3
                var a := (1.0 - t) * 0.78
                var cpos := Vector2(r["x"], r["y"])
                # soft glow — the water lifts the light
                _ellipse_local(cpos, rx * 1.15, ry * 1.6,
                        Color(E0.CYAN.r * 1.2, E0.CYAN.g * 1.2, E0.CYAN.b, a * 0.22))
                var pts := PackedVector2Array()
                for i in 14:
                        var ang := TAU * i / 14.0
                        pts.append(cpos + Vector2(cos(ang) * rx, sin(ang) * ry))
                draw_polyline(pts, Color(E0.CYAN.r * 1.35, E0.CYAN.g * 1.3, E0.CYAN.b, a), 1.6)
                if t < 0.55:
                        var pts2 := PackedVector2Array()
                        var rx2 := rx * 0.58
                        for i in 14:
                                var ang2 := TAU * i / 14.0
                                pts2.append(cpos + Vector2(cos(ang2) * rx2, sin(ang2) * rx2 * 0.3))
                        draw_polyline(pts2, Color(E0.CYAN.r * 1.3, E0.CYAN.g * 1.25, E0.CYAN.b, a * 0.8), 1.3)
        # --- droplets: bright flecks arcing out of the print
        for d in _droplets:
                var dt: float = d["t"]
                draw_circle(d["pos"], 1.1,
                        Color(E0.CYAN.r * 1.3, E0.CYAN.g * 1.3, E0.CYAN.b, (1.0 - dt * 2.0) * 0.8))

func _ellipse_local(c: Vector2, rx: float, ry: float, col: Color) -> void:
        var pts := PackedVector2Array()
        for i in 10:
                var ang := TAU * i / 10.0
                pts.append(c + Vector2(cos(ang) * rx, sin(ang) * ry))
        draw_colored_polygon(pts, col)

# ------------------------------------------------------------------ queries
# (smoke laws: the world's response is pinned, not hoped for)

func moth_count() -> int:
        return _moths.size()

func moth_leave_thresholds() -> Array:
        ## THE WORLD THINS: every moth's nerve threshold (smoke law —
        ## staggered inside the floor/ceiling band, so the departure is
        ## a wave and the population law is derivable).
        var out: Array = []
        for m in _moths:
                out.append(float(m["leave_th"]))
        return out

func moth_population_target(th: float) -> int:
        ## How many moths this room holds at thinning th (pure count over
        ## the staggered nerves — full at/below the floor, none at/above
        ## the ceiling; smoke law).
        var n := 0
        for m in _moths:
                if th <= float(m["leave_th"]):
                        n += 1
        return n

func visible_moths() -> int:
        ## How many moths are drawn right now (alpha > 0.05 — the leaving
        ## fade and the returning settle are both in flight).
        var n := 0
        for m in _moths:
                if float(m["alpha"]) > 0.05:
                        n += 1
        return n

func any_moth_leaving() -> bool:
        for m in _moths:
                if String(m["mstate"]) == "leaving":
                        return true
        return false

func moth_count_at_light(pos: Vector2) -> int:
        var n := 0
        for m in _moths:
                if (m["home"] as Vector2).distance_to(pos) < 4.0:
                        n += 1
        return n

func moth_offset(pos: Vector2) -> float:
        ## Mean burst distance of the moths at a light (scatter law probe).
        var acc := 0.0
        var n := 0
        for m in _moths:
                if (m["home"] as Vector2).distance_to(pos) < 4.0:
                        acc += (m["burst"] as Vector2).length()
                        n += 1
        return acc / float(maxi(1, n))

func scuttler_count() -> int:
        var n := 0
        for s in _scuttlers:
                if String(s["state"]) != "gone":
                        n += 1
        return n

func scuttler_total() -> int:
        return _scuttlers.size()

func any_scuttler_fleeing() -> bool:
        for s in _scuttlers:
                if String(s["state"]) == "flee":
                        return true
        return false

func bolted_scuttler() -> Vector2:
        ## The position of the first scuttler mid-flight (for its squeak).
        for s in _scuttlers:
                if String(s["state"]) == "flee":
                        return Vector2(float(s["x"]), float(s["y"]))
        return Vector2.ZERO

func ripple_count() -> int:
        return _ripples.size()
