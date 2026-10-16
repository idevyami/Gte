## THE BELIEVERS — collective belief made flesh. Chanting feeds wards and
## shields; three or more chanting empower each other; the group is the
## mechanic. Attack one and all answer. Rewrite their purpose to ABANDON and
## the ritual simply stops.
class_name Believer
extends EnemyBase

enum { CHANT, RISE, AGGRO, WINDUP, STRIKE, FLEE }

var state := CHANT
var state_t := 0.0
var ward: WardBarrier = null
var facing := 1
var aggro_all := false
var flee_target := Vector2.ZERO
var _chant_pressed := false        # WB-15: this kneel already wrote its station
var _walked_since_press := false  # WB-15: has the body moved since it last knelt
# WB-19 THE FLOCK KEEPS ITS EDGES: convergence closeness — when the flock
# presses together each robe catches its own censer's light, so the many
# bodies never bleed into one dark mass against the chapel's dark
var sep_k := 0.0
var _sep_phase := 0.0
# WB-20 THE FLOCK WALKS WITH WEIGHT: the audit's chess-piece read — the
# painted walk cycles its legs while the body glides flat. The body now
# RIDES the stride: it dips as the weight is accepted at each footfall
# (the paint's contact frames, 0 and 3), rises through the swing, and
# sways a quarter-cycle past the plant. Each body starts its cycle on its
# own frame, so the congregation never marches as one mechanism.
var _weight := Vector2.ZERO       # the live ride (painted path: the skin's offset)
var _rig_ride := Vector2.ZERO     # the same ride, for the fallback rig
var _walk_phase := 0.0            # 0..1 across the painted walk cycle
var _frame_clock := 0.0           # seconds since the skin's frame last changed
var _last_skin_frame := -1
var _walk_armed := false           # stagger applied for this walk
var _stagger_seed := -1           # the frame this body begins its cycle on
var _walk_frames := 6             # derived from the skin at walk entry
var _walk_fps := 8.0
var _censer_lag := 0.0            # the hanging lamp trails the sway (rig path)

func setup_believer(p_pos: Vector2, p_ward: WardBarrier = null, p_kneel := true) -> void:
        setup_enemy("BELIEVER", "BELIEVER_%d" % [randi() % 800 + 150])
        hp = E0.BELIEVER_HP
        max_hp = hp
        contact_damage = E0.BELIEVER_DMG
        global_position = p_pos
        ward = p_ward
        state = CHANT if p_kneel else RISE

func is_chanting() -> bool:
        return state == CHANT and not dead

func gait_key() -> String:
        ## THE SHUFFLE (WB-15): short soft-soled steps — the congregation
        ## moves in cloth, not boots. Their deeper mark is the knee-press
        ## (see _press_station).
        return "believer"

func _act(delta: float) -> void:
        state_t += delta
        var pp := _player_pos()
        facing = 1 if pp.x > global_position.x else -1
        # THE KNEE-PRESS (WB-15): entering the chant presses the station
        # into the floor — once per kneel, and only once the body has
        # landed (a station floats nowhere)
        if state == CHANT:
                if not _chant_pressed and is_on_floor():
                        _chant_pressed = true
                        _press_station()
        else:
                _chant_pressed = false
        if state in [AGGRO, STRIKE, FLEE] and absf(velocity.x) > 30.0:
                _walked_since_press = true
        match state:
                CHANT:
                        aggro = false
                        velocity.x = 0.0
                        if ward and not is_instance_valid(ward):
                                ward = null
                RISE:
                        velocity.x = 0.0
                        if state_t > 0.6:
                                state = CHANT if not _player_near(340.0) else RISE
                                state_t = 0.0
                AGGRO:
                        aggro = true
                        velocity.x = signf(pp.x - global_position.x) * 120.0
                        if absf(pp.x - global_position.x) < 44.0 and state_t > 0.5:
                                state = WINDUP
                                state_t = 0.0
                                telegraph_t = 0.45   # the warning ring, wound once
                        elif absf(pp.x - global_position.x) > 560.0:
                                state = CHANT
                                state_t = 0.0
                WINDUP:
                        velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
                        if state_t > 0.5:
                                state = STRIKE
                                state_t = 0.0
                                AudioManager.play_sfx("sfx_swing_a", -8.0)
                STRIKE:
                        velocity.x = facing * 260.0
                        if state_t > 0.25:
                                state = AGGRO
                                state_t = 0.0
                FLEE:
                        velocity.x = signf(flee_target.x - global_position.x) * 200.0
                        if absf(flee_target.x - global_position.x) < 30.0 or state_t > 6.0:
                                _abandon_fade()
        velocity.y += 1500.0 * delta if not is_on_floor() else 0.0
        _convergence_update(delta)
        _weight_update(delta)

func _convergence_update(delta: float) -> void:
        ## THE FLOCK KEEPS ITS EDGES (WB-19): the motion audit's silhouette
        ## finding — converging believers read as one shape. Each body now
        ## knows its nearest neighbor and carries a catch-light that rises
        ## as the flock closes (full inside a body's width, gone past two).
        _sep_phase += delta
        var best := 1e9
        for node in get_tree().get_nodes_in_group("enemies"):
                var b := node as Believer
                if b == null or b == self or b.dead:
                        continue
                best = minf(best, absf(b.global_position.x - global_position.x))
        var want := clampf((110.0 - best) / 55.0, 0.0, 1.0)
        sep_k = lerpf(sep_k, want, delta * 8.0)

func _weight_update(delta: float) -> void:
        ## WB-20 THE RIDE, in time: the rig path's weight (the painted path
        ## derives its own in _sync_skin, anchored to the skin's frames).
        ## The rig's legs scissor at sin(anim_t * 9); the pass/plant is the
        ## crossing — the body dips there, rises through the swing, and
        ## sways a quarter behind. The censer hangs and trails (a pendulum).
        if state in [AGGRO, STRIKE, FLEE] and absf(velocity.x) > 20.0:
                var th := anim_t * 9.0
                _rig_ride = Vector2(
                        sin(th * 2.0) * E0.BELIEVER_RIDE_SWAY * facing,
                        cos(th * 2.0) * E0.BELIEVER_RIDE_DIP)
        else:
                _rig_ride = _rig_ride.lerp(Vector2.ZERO, minf(1.0, delta * 10.0))
        var want_lag := 0.0
        if absf(_rig_ride.x) > 0.05:
                want_lag = -_rig_ride.x * (E0.BELIEVER_CENSER_SWING
                        / maxf(0.1, E0.BELIEVER_RIDE_SWAY))
        _censer_lag = lerpf(_censer_lag, want_lag, delta * 6.0)

func _press_station() -> void:
        ## THE STATION'S AGE (WB-15): a press the vessel never saw kneel is
        ## born OLD — the devotion predates his arrival (the chapel was
        ## full of prayer before he ever walked in). A press after walking
        ## is fresh: darker, present, now. The record keeps up with the
        ## living either way.
        var tr := _trace_layer()
        if tr == null:
                return
        var pre := 0.0
        if not _walked_since_press:
                pre = randf_range(6.0, 9.0)
        _walked_since_press = false
        tr.stamp_kneel(global_position + Vector2(0.0, 4.0), float(facing), pre)

func _player_near(r: float) -> bool:
        return absf(_player_pos().x - global_position.x) < r

func _contact_damages() -> bool:
        return state == STRIKE

func _on_hurt() -> void:
        # Harm one and the ward weakens — and every believer answers.
        _spread_aggro()
        if state in [CHANT, RISE]:
                state = AGGRO
                state_t = 0.0

func _spread_aggro() -> void:
        if aggro_all:
                return
        aggro_all = true
        for node in get_tree().get_nodes_in_group("enemies"):
                var b := node as Believer
                if b and b != self and not b.dead and b.state in [CHANT, RISE]:
                        b.state = AGGRO
                        b.state_t = 0.0

func begin_flee() -> void:
        ## Called when the censer's purpose is rewritten to ABANDON: the ritual
        ## stops, the believers scatter, the belief gauge collapses.
        if dead or state == FLEE:
                return
        data.set_state("ABANDONED")
        data.properties["purpose"]["value"] = "ABANDON"
        state = FLEE
        state_t = 0.0
        flee_target = global_position + Vector2(-signf(facing) * 600.0, 0.0)
        velocity = Vector2.ZERO

func _abandon_fade() -> void:
        dead = true
        death_t = 0.4
        GameState.stats["dissipated"] += 1

# empowerment: +25% damage per chanter beyond two (they believe each other strong)
func damage_mult() -> float:
        var chanters := 0
        for node in get_tree().get_nodes_in_group("enemies"):
                var b := node as Believer
                if b and not b.dead and b.is_chanting():
                        chanters += 1
        var bonus: float = 0.25 * maxi(0, chanters - 2)
        return minf(2.0, 1.0 + bonus)

func _on_contact(body: Node2D) -> void:
        if state == STRIKE and body is Player and contact_cd <= 0.0:
                contact_cd = 0.9
                body.take_damage(int(float(contact_damage) * damage_mult()), global_position)

func _sync_skin(delta: float) -> void:
        super(delta)
        if _skin == null:
                return
        ## WB-20 THE PAINTED RIDE: the skin rides its own walk — the offset
        ## is derived from the ACTUAL painted frame (re-anchored at every
        ## frame change so the ride can never drift from the paint) plus a
        ## sub-frame clock for the in-between. Contacts sit at frames 0 and
        ## 3 (the paint's own footfalls): dip there, rise mid-swing, sway a
        ## quarter past each plant, mirrored with facing (the planted side
        ## flips with the sprite). Off the walk the ride relaxes to zero —
        ## the kneel, the strike and the corpse do not bob.
        var walking := not dead and _skin.animation == "walk" and absf(velocity.x) > 20.0
        if walking:
                if not _walk_armed:
                        _walk_armed = true
                        _walk_frames = maxi(2, _skin.sprite_frames.get_frame_count("walk"))
                        _walk_fps = maxf(1.0, _skin.sprite_frames.get_animation_speed("walk"))
                        # each body begins its cycle alone — the flock is a
                        # congregation, not a chorus line
                        _stagger_seed = int(absf(fmod(global_position.x * 0.61, float(_walk_frames))))
                        _skin.frame = _stagger_seed
                        _last_skin_frame = _stagger_seed
                        _frame_clock = 0.0
                if _skin.frame != _last_skin_frame:
                        _last_skin_frame = _skin.frame
                        _frame_clock = 0.0
                else:
                        _frame_clock = minf(_frame_clock + delta, 1.0 / _walk_fps)
                _walk_phase = fmod((float(_last_skin_frame) + _frame_clock * _walk_fps)
                        / float(_walk_frames), 1.0)
                _weight = Vector2(
                        sin(TAU * 2.0 * _walk_phase) * E0.BELIEVER_RIDE_SWAY * facing,
                        cos(TAU * 2.0 * _walk_phase) * E0.BELIEVER_RIDE_DIP)
        else:
                _walk_armed = false
                _weight = _weight.lerp(Vector2.ZERO, minf(1.0, delta * 10.0))
        _skin.position = _weight

func skin_set() -> String:
        return "believers"

func skin_fps() -> Dictionary:
        return {"kneel": 1.6, "walk": 8.0, "strike": 8.0, "hurt": 11.0, "death": 2.6}

func skin_facing() -> int:
        return facing

func skin_pose() -> String:
        match state:
                CHANT, RISE:
                        return "kneel"
                WINDUP, STRIKE:
                        return "strike"
                _:
                        return "walk" if absf(velocity.x) > 20.0 else "kneel"

func _draw_body() -> void:
        _draw_convergence_edge()
        # painted skin active: keep only the windup telegraph flash
        if _skin != null and not GameState.debug_no_sprites:
                if state == WINDUP:
                        var k2 := clampf(state_t / 0.5, 0.0, 1.0)
                        draw_line(Vector2(facing * 14.0, -36.0), Vector2(facing * (14.0 + 60.0 * k2), -36.0),
                                Color(E0.CRIMSON.r, E0.CRIMSON.g, E0.CRIMSON.b, 0.2 + 0.3 * k2), 2.0)
                return
        var col := E0.VIOLET.darkened(0.15)
        if hurt_flash > 0.0:
                col = col.lerp(Color(0.9, 0.75, 0.6), hurt_flash / 0.26)
        match state:
                CHANT:
                        _draw_kneeling(col)
                RISE:
                        _draw_kneeling(col)
                _:
                        _draw_standing(col)

func _draw_convergence_edge() -> void:
        ## THE FLOCK KEEPS ITS EDGES (WB-19): a thin censer-warm rim on the
        ## robe's bounds, breathing per-body (no two pulse in step) — the
        ## ground pool doubles the separation where the feet meet the runner.
        if sep_k <= 0.02 or dead:
                return
        var breathe := 0.8 + 0.2 * sin(_sep_phase * 3.1 + global_position.x * 0.7)
        var a := 0.24 * sep_k * breathe
        var col := Color(0.86, 0.74, 0.52)
        # WB-20: the rim rides mostly with the body (damped 0.85) so the glow
        # stays glued to the robe it edges while the ride moves — but the
        # ground pool never rides: it is the floor's light, and the floor
        # does not walk (the rim follows whichever body is visible)
        var painted := _skin != null and not GameState.debug_no_sprites
        var rim_ride := (_weight if painted else _rig_ride) * 0.85
        # the robe's bounds: taller when standing, settled when kneeling
        var cy := -30.0 + rim_ride.y
        var ry := 33.0
        if state == CHANT or state == RISE:
                cy = -22.0
                ry = 25.0
        var pts := PackedVector2Array()
        for i in 22:
                var t := TAU * i / 22.0
                pts.append(Vector2(rim_ride.x, cy) + Vector2(cos(t) * 13.5, sin(t) * ry))
        draw_polyline(pts, Color(col.r, col.g, col.b, a), 1.6)
        # the censer's light pools at the feet — the ground separates too,
        # and the pool breathes with the shuffle (the re-audit: static pools
        # read as chess-pieces, not walkers)
        var pool_a := a * 0.7
        if absf(velocity.x) > 20.0:
                pool_a *= 0.75 + 0.25 * sin(anim_t * 9.0)
        draw_polyline(_ellipse(Vector2(0, 1), 15.0, 4.2), Color(col.r, col.g, col.b, pool_a), 1.4)

func _draw_kneeling(col: Color) -> void:
        var sway := sin(anim_t * 1.8 + global_position.x * 0.05) * 2.0
        # kneeling robe
        draw_colored_polygon(PackedVector2Array([
                Vector2(-11, 0), Vector2(11, 0), Vector2(9 + sway, -34), Vector2(-9 + sway, -34),
        ]), col)
        draw_circle(Vector2(sway, -39), 7.0, col)
        # bowed hood
        draw_rect(Rect2(sway - 5.0, -42, 10, 6), E0.VOID)
        # censer held forward, thin gold thread of smoke
        draw_line(Vector2(sway + 8, -26), Vector2(sway + 15, -22), Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.8), 2.0)
        draw_circle(Vector2(sway + 15, -20), 3.5, E0.GOLD.darkened(0.35))
        var t := fmod(anim_t * 0.5, 1.0)
        draw_circle(Vector2(sway + 15 + sin(t * TAU) * 4.0, -24.0 - t * 22.0), 2.0 - t, Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, (1.0 - t) * 0.25))
        # chanting marks rise from them
        if fmod(anim_t, 2.0) < 1.0:
                var k := fmod(anim_t, 2.0)
                draw_rect(Rect2(sway - 2.0, -46.0 - k * 16.0, 4, 3), Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, (1.0 - k) * 0.3))

func _draw_standing(col: Color) -> void:
        var stride := sin(anim_t * 9.0) * 4.0 if absf(velocity.x) > 20.0 else 0.0
        # WB-20 THE RIG RIDES TOO: the same weight the painted body rides —
        # the hips rise and settle while the feet stay planted (the legs
        # pivot at the hip, they do not translate), the torso sways over
        # the settling side, and the censer trails the sway like the
        # pendulum it is (it hangs from the arm, it is not held)
        var ride := _rig_ride
        var hip := -26.0 + ride.y
        draw_line(Vector2(-3 + stride, hip), Vector2(-4, 0), col, 3.5)
        draw_line(Vector2(3 - stride, hip), Vector2(4, 0), col, 3.5)
        draw_colored_polygon(PackedVector2Array([
                Vector2(-9 + ride.x, hip), Vector2(9 + ride.x, hip),
                Vector2(10 + ride.x, hip - 26.0), Vector2(-10 + ride.x, hip - 26.0),
        ]), col)
        draw_circle(Vector2(ride.x, hip - 32.0), 7.5, col)
        draw_rect(Rect2(facing * 2.0 - 3.0 + ride.x, hip - 35.0, 6, 5), E0.VOID)
        # arm with hanging censer — a weapon they never chose
        var arm := Vector2(facing * 12.0 + ride.x, hip - 14.0)
        if state == WINDUP:
                var k := clampf(state_t / 0.5, 0.0, 1.0)
                arm = Vector2(facing * (12.0 - 6.0 * k) + ride.x, hip - 14.0 + 14.0 * k)
                col = col.lerp(E0.CRIMSON, k * 0.5)
        draw_line(Vector2(facing * 6.0 + ride.x, hip - 20.0), arm, col, 3.0)
        draw_line(arm, arm + Vector2(_censer_lag, 10.0), Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.8), 1.5)
        draw_circle(arm + Vector2(_censer_lag, 12.0), 3.5, E0.GOLD.darkened(0.3))
        if state == WINDUP:
                var k2 := clampf(state_t / 0.5, 0.0, 1.0)
                draw_line(Vector2(facing * 14.0, -36.0), Vector2(facing * (14.0 + 60.0 * k2), -36.0),
                        Color(E0.CRIMSON.r, E0.CRIMSON.g, E0.CRIMSON.b, 0.2 + 0.3 * k2), 2.0)
        draw_colored_polygon(_ellipse(Vector2(0, 1), 12.0, 3.0), Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.3))

func _ellipse(center: Vector2, rx: float, ry: float) -> PackedVector2Array:
        var pts := PackedVector2Array()
        for i in 10:
                var a := TAU * i / 10.0
                pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
        return pts

func _draw_death() -> void:
        super()
        # painted collapse active: no procedural body double
        if _skin != null and not GameState.debug_no_sprites:
                return
        if death_t < 0.5 and state == FLEE:
                var alpha := clampf(1.0 - death_t * 2.0, 0.0, 1.0)
                draw_colored_polygon(PackedVector2Array([
                        Vector2(-9, 0), Vector2(9, 0), Vector2(10, -52), Vector2(-10, -52),
                ]), Color(E0.VIOLET.r, E0.VIOLET.g, E0.VIOLET.b, alpha * 0.4))
