## PlayerRig — the vessel, drawn. Articulated polygon animation: walk cycle,
## cloak sway, attack arcs with trails, roll tumble, death collapse, contact
## shadow. No sprites: the figure is generated geometry, graded by the post FX.
class_name PlayerRig
extends Node2D

var player: Player

var _walk := 0.0
var _idle := 0.0
var _swing := {"active": false, "idx": 0, "t": 0.0, "dir": 1}
var _death_t := -1.0
var _land_squash := 0.0

func _ready() -> void:
        z_index = 5

func sync_state(delta: float) -> void:
        if player == null:
                return
        _idle += delta
        if player.is_on_floor() and absf(player.velocity.x) > 30.0 and not player.is_rolling():
                _walk += absf(player.velocity.x) * delta * 0.055
        if player.is_on_floor() and absf(player.velocity.y) < 1.0:
                _land_squash = maxf(0.0, _land_squash - delta * 3.0)
        if _swing["active"]:
                _swing["t"] += delta
                if float(_swing["t"]) > 0.24:
                        _swing["active"] = false
        if _death_t >= 0.0:
                _death_t += delta
        queue_redraw()

func play_swing(idx: int, dir: int) -> void:
        _swing = {"active": true, "idx": idx, "t": 0.0, "dir": dir}

func play_death() -> void:
        _death_t = 0.0

func notify_landed() -> void:
        _land_squash = 1.0

# ------------------------------------------------------------------ drawing
func _draw() -> void:
        if player == null:
                return
        var f: int = player.facing
        var dead := _death_t >= 0.0
        var rolling := player.is_rolling()
        var flashing := player._hurt_flash > 0.0 and fmod(player._hurt_flash * 30.0, 2.0) < 1.0
        var alpha := 1.0
        if player.has_iframes() and not rolling and not dead:
                alpha = 0.45 if fmod(_idle * 24.0, 2.0) < 1.0 else 0.85
        if dead:
                alpha = clampf(1.0 - _death_t * 0.55, 0.0, 1.0)

        # --- contact shadow
        var shadow_alpha := 0.35 if player.is_on_floor() else 0.16
        draw_colored_polygon(_ellipse_pts(Vector2(0, 2), 16.0, 4.0, 10),
                Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, shadow_alpha * alpha))

        var bob := sin(_idle * 2.2) * 1.2 if absf(player.velocity.x) < 30.0 else 0.0
        var squash := 1.0 - _land_squash * 0.22
        var lean := clampf(player.velocity.x * 0.018, -0.12, 0.12)

        if rolling:
                _draw_roll(f, alpha)
                return
        if dead:
                _draw_death(f, alpha)
                return

        # --- legs (from hip y=-22 to ground)
        var speed01 := clampf(absf(player.velocity.x) / E0.P_MAX_SPEED, 0.0, 1.0)
        var air := not player.is_on_floor()
        var phase_a := _walk * TAU
        var l1 := _leg_points(-3.0, phase_a, speed01, air, f)
        var l2 := _leg_points(3.0, phase_a + PI, speed01, air, f)
        _draw_limb(l1, E0.CHARCOAL.darkened(0.15))
        _draw_limb(l2, E0.CHARCOAL)

        # --- cloak / torso
        var hip := Vector2(0, -22 + bob)
        var shoulder := Vector2(lean * 14.0 * f, -44 + bob)
        var cloak := PackedVector2Array([
                hip + Vector2(-8, 2), hip + Vector2(8, 2),
                shoulder + Vector2(9, 0), shoulder + Vector2(-9, 0),
        ])
        # trailing hem while moving
        if speed01 > 0.2 and player.is_on_floor():
                cloak[0] += Vector2(-f * speed01 * 6.0, 1.5)
        draw_colored_polygon(cloak, Color(E0.CHARCOAL.r, E0.CHARCOAL.g, E0.CHARCOAL.b, alpha))
        # gold trim at hem
        draw_line(cloak[0] + Vector2(0, -2), cloak[1] + Vector2(0, -2),
                Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.55 * alpha), 1.0)

        # --- hood + face
        var head := shoulder + Vector2(lean * 6.0 * f, -8)
        draw_colored_polygon(PackedVector2Array([
                head + Vector2(-8, 2), head + Vector2(8, 2),
                head + Vector2(9, -6), head + Vector2(5, -10),
                head + Vector2(-5, -10), head + Vector2(-9, -6),
        ]), Color(E0.CHARCOAL.darkened(0.1).r, E0.CHARCOAL.darkened(0.1).g, E0.CHARCOAL.darkened(0.1).b, alpha))
        # face slit
        draw_colored_polygon(PackedVector2Array([
                head + Vector2(f * 1.0, -8), head + Vector2(f * 6.5, -7),
                head + Vector2(f * 6.5, -3), head + Vector2(f * 1.0, -4),
        ]), Color(E0.BONE.r, E0.BONE.g, E0.BONE.b, 0.9 * alpha))
        # cyan eye glints
        draw_circle(head + Vector2(f * 2.6, -6.5), 1.1, Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, alpha))
        draw_circle(head + Vector2(f * 5.0, -6.2), 0.9, Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.7 * alpha))

        # --- arm + ritual blade
        if _swing["active"]:
                _draw_swing(f, alpha)
        else:
                # sheathed hilt at hip
                draw_line(hip + Vector2(f * 7, 0), hip + Vector2(f * 10, -4),
                        Color(E0.BONE.r, E0.BONE.g, E0.BONE.b, 0.8 * alpha), 2.0)
                # idle arm
                draw_line(shoulder + Vector2(f * 4, 0), shoulder + Vector2(f * 7, 12),
                        Color(E0.CHARCOAL.darkened(0.2).r, E0.CHARCOAL.darkened(0.2).g, E0.CHARCOAL.darkened(0.2).b, alpha), 3.0)

        if flashing:
                draw_colored_polygon(cloak, Color(0.85, 0.2, 0.2, 0.35))

func _leg_points(side: float, phase: float, speed01: float, air: bool, f: int) -> PackedVector2Array:
        var hip := Vector2(side, -22)
        var knee := hip + Vector2(sin(phase) * 5.0 * speed01 * f, 11)
        var foot := knee + Vector2(sin(phase) * 7.0 * speed01 * f, 11 - absf(cos(phase)) * 3.0 * speed01)
        if air:
                knee = hip + Vector2(side * 1.5, 9)
                foot = knee + Vector2(f * 3.0, 8)
        return PackedVector2Array([hip, knee, foot])

func _draw_limb(pts: PackedVector2Array, col: Color) -> void:
        draw_line(pts[0], pts[1], col, 4.0)
        draw_line(pts[1], pts[2], col, 3.0)
        draw_circle(pts[2], 2.0, col.darkened(0.25))

func _draw_swing(f: int, alpha: float) -> void:
        var t: float = float(_swing["t"]) / 0.22
        var idx: int = int(_swing["idx"])
        var shoulder := Vector2(0, -42)
        # sweep arc: windup to extension (angle from forward-down, facing applied by dir_vec)
        var start_deg := -70.0
        var end_deg := 85.0
        var ang: float = lerpf(start_deg, end_deg, clampf(t * 1.35, 0.0, 1.0))
        var arm_len := 20.0 + 8.0 * idx
        var dir_vec := Vector2(f, 0).rotated(deg_to_rad(-ang))
        var hand := shoulder + dir_vec * arm_len
        draw_line(shoulder, hand, Color(E0.CHARCOAL.darkened(0.2).r, E0.CHARCOAL.darkened(0.2).g, E0.CHARCOAL.darkened(0.2).b, alpha), 4.0)
        # blade
        var blade_len := 26.0 + 7.0 * idx
        var blade_tip := hand + dir_vec * blade_len
        var guard := hand + dir_vec * 4.0
        draw_line(hand, guard, Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, alpha), 3.0)
        draw_line(guard, blade_tip, Color(E0.BONE.r, E0.BONE.g, E0.BONE.b, alpha), 2.5)
        # motion trail: fading arcs behind the swing
        var trail_alpha := clampf(0.55 * (1.0 - t), 0.0, 0.55) * alpha
        if trail_alpha > 0.03:
                var radius := arm_len + blade_len * 0.6
                for i in 3:
                        var a0 := deg_to_rad(start_deg + (end_deg - start_deg) * clampf(t - 0.12 * (i + 1), 0.0, 1.0))
                        var a1 := deg_to_rad(start_deg + (end_deg - start_deg) * clampf(t - 0.04 * (i + 1), 0.0, 1.0))
                        if absf(a1 - a0) > 0.02:
                                var pts := PackedVector2Array()
                                for k in 6:
                                        var aa := lerp_angle(a0, a1, float(k) / 5.0)
                                        pts.append(shoulder + Vector2(f, 0).rotated(-aa) * radius)
                                for k in range(pts.size() - 1):
                                        draw_line(pts[k], pts[k + 1], Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, trail_alpha * (1.0 - i * 0.3)), 3.0 - i * 0.8)

func _draw_roll(f: int, alpha: float) -> void:
        var t: float = 1.0 - player._roll_t / E0.P_ROLL_TIME
        var rot := t * TAU * 1.5 * f
        var center := Vector2(0, -14)
        var pts := PackedVector2Array()
        for i in 8:
                var a := rot + TAU * i / 8.0
                pts.append(center + Vector2(cos(a) * 12.0, sin(a) * 12.0))
        draw_colored_polygon(pts, Color(E0.CHARCOAL.r, E0.CHARCOAL.g, E0.CHARCOAL.b, alpha))
        # hood remnant visible in the tumble
        var hood := center + Vector2(cos(rot) * 6.0, sin(rot) * 6.0)
        draw_circle(hood, 4.0, Color(E0.CHARCOAL.darkened(0.2).r, E0.CHARCOAL.darkened(0.2).g, E0.CHARCOAL.darkened(0.2).b, alpha))
        draw_circle(hood + Vector2(2.0 * f, -1.0), 1.0, Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, alpha))

func _draw_death(f: int, alpha: float) -> void:
        var t := _death_t
        var fall := clampf(t * 1.6, 0.0, 1.0)
        var rot := deg_to_rad(-84.0 * f * fall)
        var pivot := Vector2(0, 0)
        var body := PackedVector2Array([
                Vector2(-7, -46), Vector2(7, -46), Vector2(8, -6), Vector2(-8, -6),
        ])
        for i in body.size():
                body[i] = pivot + (body[i] - pivot).rotated(rot)
        draw_colored_polygon(body, Color(E0.CHARCOAL.r, E0.CHARCOAL.g, E0.CHARCOAL.b, alpha))
        var head := pivot + (Vector2(f * 2.0, -52.0) - pivot).rotated(rot)
        draw_circle(head, 7.0, Color(E0.CHARCOAL.darkened(0.1).r, E0.CHARCOAL.darkened(0.1).g, E0.CHARCOAL.darkened(0.1).b, alpha))
        # ash motes rising from the collapse
        if t < 2.0:
                for i in 7:
                        var seed_a := float(i) * 2.399
                        var p := Vector2(cos(seed_a) * 10.0, -6.0 - (t * 22.0 + fmod(seed_a, 8.0)) * 0.6)
                        draw_circle(p + Vector2(sin(_idle * 3.0 + seed_a) * 3.0, 0), 1.2,
                                Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, clampf(0.5 - t * 0.25, 0.0, 0.5)))

func _ellipse_pts(center: Vector2, rx: float, ry: float, segments: int) -> PackedVector2Array:
        var pts := PackedVector2Array()
        for i in segments:
                var a := TAU * i / segments
                pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
        return pts
