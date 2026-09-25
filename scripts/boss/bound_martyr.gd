## THE BOUND MARTYR — ENTITY_000_001, the first. Suffering became purpose.
## 900 HP, three phases: bound sweeps behind a belief shield (Phase 1),
## FERVOR arena-shrink + dash + consistency drain (Phase 2), unchained leaping
## desperation (Phase 3). OBSERVE data evolves; the death sequence is scripted.
class_name BoundMartyr
extends EnemyBase

enum { INTRO, IDLE, WINDUP, ATTACK, DASH_WINDUP, DASHING, LEAP_WINDUP, LEAPING, RECOVER, DYING, DEAD }

var state := INTRO
var state_t := 0.0
var phase := 1
var facing := -1
var attack_pattern := 0
var fervor_l := 340.0
var fervor_r := 1260.0
var fervor_t := 0.0
var arena_l := 300.0
var arena_r := 1300.0
var floor_y := 0.0
var dash_dir := 1
var leap_target := Vector2.ZERO
var chain_breaks := 0
var _death_msec := 0
var intro_done := false
var _aura_accum := 0.0
var _bearers: Array = []

func setup_martyr(p_pos: Vector2, p_arena: Vector2, p_floor_y: float) -> void:
        setup_enemy("BOUND_MARTYR", "BOUND_MARTYR")
        hp = E0.MARTYR_HP
        max_hp = hp
        contact_damage = 0
        global_position = p_pos
        arena_l = p_arena.x
        arena_r = p_arena.y
        floor_y = p_floor_y
        data.set_state("BOUND — SUFFERING USEFUL")
        data.notes = ["the first. the failed. the repurposed."]

func register_bearers(bearers: Array) -> void:
        _bearers = bearers

func shielded() -> bool:
        for b in _bearers:
                if is_instance_valid(b) and not b.is_dead() and b.is_chanting():
                        return true
        return false

# ------------------------------------------------------------------ phases
func _act(delta: float) -> void:
        state_t += delta
        gravity_pass(delta)
        match state:
                INTRO:
                        velocity.x = 0.0
                IDLE:
                        _shamble(delta)
                        if state_t > _cadence():
                                _choose_attack()
                WINDUP:
                        velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
                        if state_t > _windup_time():
                                _execute_attack()
                ATTACK:
                        if state_t > 0.4:
                                state = RECOVER
                                state_t = 0.0
                DASH_WINDUP:
                        velocity.x = 0.0
                        if state_t > 0.7:
                                state = DASHING
                                state_t = 0.0
                                dash_dir = facing
                                AudioManager.play_sfx("sfx_boss_roar", -6.0)
                DASHING:
                        velocity.x = dash_dir * 520.0
                        _dash_damage_check()
                        if state_t > 0.5 or global_position.x < arena_l + 40.0 or global_position.x > arena_r - 40.0:
                                state = RECOVER
                                state_t = 0.0
                                FX.shake(5.0, 0.3)
                                AudioManager.play_sfx("sfx_boss_impact", -4.0)
                LEAP_WINDUP:
                        velocity.x = 0.0
                        if state_t > 0.6:
                                state = LEAPING
                                state_t = 0.0
                                var player := get_tree().get_first_node_in_group("player") as Player
                                leap_target = player.global_position if player else global_position
                                leap_target.x = clampf(leap_target.x, arena_l + 60.0, arena_r - 60.0)
                                velocity = Vector2((leap_target.x - global_position.x) / 0.55, -520.0)
                LEAPING:
                        if is_on_floor() and state_t > 0.2:
                                _slam_damage_check()
                                state = RECOVER
                                state_t = 0.0
                                FX.shake(10.0, 0.5)
                                AudioManager.play_sfx("sfx_boss_impact", 0.0)
                RECOVER:
                        velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
                        if state_t > _recover_time():
                                state = IDLE
                                state_t = 0.0
                DYING:
                        _death_sequence(delta)
                DEAD:
                        velocity.x = 0.0
        _phase_update(delta)
        _fervor_update(delta)
        _facing_update()

func gravity_pass(delta: float) -> void:
        if not is_on_floor():
                velocity.y += 1600.0 * delta
        else:
                velocity.y = minf(velocity.y, 0.0)

func _cadence() -> float:
        return [2.4, 1.9, 1.6][phase - 1]

func _windup_time() -> float:
        return [0.7, 0.6, 0.55][phase - 1]

func _recover_time() -> float:
        return [0.9, 0.7, 0.55][phase - 1]

func _shamble(delta: float) -> void:
        var player := get_tree().get_first_node_in_group("player") as Player
        if player == null:
                return
        var dir := signf(player.global_position.x - global_position.x)
        var sp := 40.0 + 18.0 * phase
        if phase == 1:
                # bound: shambles between the pillars, dragging chains
                if global_position.x < arena_l + 120.0 or global_position.x > arena_r - 120.0:
                        dir = -dir
                velocity.x = dir * sp * 0.6
        else:
                velocity.x = dir * sp
        velocity.x = move_toward(velocity.x, velocity.x, 1000.0 * delta)

func _facing_update() -> void:
        var player := get_tree().get_first_node_in_group("player") as Player
        if player:
                facing = 1 if player.global_position.x > global_position.x else -1

func _choose_attack() -> void:
        state = WINDUP
        state_t = 0.0
        attack_pattern = (attack_pattern + 1) % 3
        match phase:
                1:
                        attack_pattern = attack_pattern % 2      # low / high sweeps only
                2:
                        if attack_pattern == 2:
                                state = DASH_WINDUP
                3:
                        if attack_pattern == 2:
                                state = LEAP_WINDUP
        AudioManager.play_sfx("sfx_boss_chain", -6.0)

func _execute_attack() -> void:
        state = ATTACK
        state_t = 0.0
        AudioManager.play_sfx("sfx_swing_c", -2.0)
        var player := get_tree().get_first_node_in_group("player") as Player
        if player == null:
                return
        var in_range := absf(player.global_position.x - global_position.x) < 190.0
        var dmg: int = E0.MARTYR_DMG[phase - 1]
        match attack_pattern:
                0:
                        # SWEEP LOW — jump over it
                        if in_range and player.is_on_floor() and player.velocity.y >= -20.0:
                                player.take_damage(dmg, global_position)
                1:
                        # SWEEP HIGH — roll under it
                        if in_range and not player.is_rolling():
                                player.take_damage(dmg, global_position)
                2:
                        # 360 (phase 3 only reaches here when not leaping)
                        if player.global_position.distance_to(global_position) < 150.0 and not player.has_iframes():
                                player.take_damage(dmg, global_position)

func _dash_damage_check() -> void:
        var player := get_tree().get_first_node_in_group("player") as Player
        if player and absf(player.global_position.x - global_position.x) < 70.0 and not player.has_iframes():
                player.take_damage(E0.MARTYR_DMG[1], global_position)

func _slam_damage_check() -> void:
        var player := get_tree().get_first_node_in_group("player") as Player
        if player == null:
                return
        if player.global_position.distance_to(leap_target) < 110.0 and not player.has_iframes():
                player.take_damage(E0.MARTYR_DMG[2], leap_target)

func _phase_update(delta: float) -> void:
        if phase == 2 and state in [IDLE, WINDUP, RECOVER]:
                # FERVOR: the arena contracts and his suffering drains consistency nearby
                _aura_accum += delta
                if _aura_accum >= 1.0:
                        _aura_accum = 0.0
                        var player := get_tree().get_first_node_in_group("player") as Player
                        if player and player.global_position.distance_to(global_position) < 150.0:
                                GameState.spend(int(E0.BOSS_AURA_DRAIN), "fervor")
        if state == DYING or state == DEAD or state == INTRO:
                return
        if phase == 1 and hp <= E0.MARTYR_P2_AT:
                phase = 2
                _enter_phase2()
        elif phase == 2 and hp <= E0.MARTYR_P3_AT:
                phase = 3
                _enter_phase3()

func _enter_phase2() -> void:
        state = RECOVER
        state_t = 0.0
        data.set_state("FERVOR — BELIEVED USEFUL")
        AudioManager.play_music("boss_p2")
        AudioManager.play_sfx("sfx_boss_roar", 0.0)
        FX.shake(8.0, 0.6)
        FX.tear_pulse(0.9)
        var game := get_tree().get_first_node_in_group("game")
        if game:
                game.start_dialogue("martyr_p2")

func _enter_phase3() -> void:
        state = RECOVER
        state_t = 0.0
        phase = 3
        data.set_state("UNCHAINED")
        data.purpose = "BE REMEMBERED"
        data.notes = ["the first. the failed. the repurposed.", "he no longer believes in the design."]
        AudioManager.play_music("boss_p3")
        AudioManager.play_sfx("sfx_boss_chain", 2.0)
        AudioManager.play_sfx("sfx_boss_roar", 2.0)
        FX.shake(12.0, 0.8)
        var game := get_tree().get_first_node_in_group("game")
        if game:
                game.start_dialogue("martyr_p3")

func _fervor_update(delta: float) -> void:
        if phase != 2 or state in [DYING, DEAD, INTRO]:
                return
        fervor_t += delta
        var k := clampf(fervor_t / 40.0, 0.0, 1.0)
        fervor_l = lerpf(340.0, 480.0, k)
        fervor_r = lerpf(1260.0, 1120.0, k)
        var player := get_tree().get_first_node_in_group("player") as Player
        if player and player.hp > 0:
                var outside := player.global_position.x < fervor_l or player.global_position.x > fervor_r
                if outside and not player.has_iframes():
                        _fervor_tick(player, delta)

var _fervor_accum := 0.0
func _fervor_tick(player: Player, delta: float) -> void:
        _fervor_accum += delta
        if _fervor_accum > 0.8:
                _fervor_accum = 0.0
                player.take_damage(12, player.global_position)

# ------------------------------------------------------------------ damage / shield
func take_hit(dmg: int, from_pos: Vector2, heavy: bool) -> void:
        if state == INTRO or state == DYING or state == DEAD:
                return
        var applied := dmg
        if shielded():
                applied = maxi(1, int(round(dmg * 0.2)))
                AudioManager.play_sfx("sfx_barrier_break", -12.0, false)
        super(applied, from_pos, heavy)

func begin_fight() -> void:
        if intro_done:
                return
        intro_done = true
        state = IDLE
        state_t = 0.0
        AudioManager.play_music("boss_p1")

# ------------------------------------------------------------------ death
func _die() -> void:
        if state == DYING or state == DEAD:
                return
        state = DYING
        state_t = 0.0
        _death_msec = Time.get_ticks_msec()
        chain_breaks = 0
        velocity = Vector2.ZERO
        data.set_state("RELEASED")
        AudioManager.play_music("aftermath")

func _death_sequence(_delta: float) -> void:
        # chains snap one by one, he kneels, thanks you, and comes apart
        # (wall-clock driven: the cinematic must not depend on frame rate)
        var elapsed: float = float(Time.get_ticks_msec() - _death_msec) * 0.001
        if chain_breaks < 3 and elapsed > 0.8 * (chain_breaks + 1):
                chain_breaks += 1
                AudioManager.play_sfx("sfx_boss_chain", 2.0)
                FX.shake(6.0, 0.3)
        if chain_breaks >= 3 and elapsed > 3.0 and not GameState.has_flag("martyr_thanked"):
                var game := get_tree().get_first_node_in_group("game")
                if game:
                        GameState.set_flag("martyr_thanked")
                        if game.has_method("start_dialogue"):
                                game.start_dialogue("martyr_death")
        if elapsed > 8.0 and state != DEAD:
                state = DEAD
                dead = true
                death_t = 0.4
                GameState.boss_defeated = true
                EventBus.boss_defeated.emit("BOUND_MARTYR")
                FX.shake(4.0, 0.4)
                AudioManager.play_sfx("sfx_reveal", 0.0)
                # Game listens on the boss_defeated signal: the monument persists.

func is_dead_state() -> bool:
        return state == DEAD

func _contact_damages() -> bool:
        return false

# ------------------------------------------------------------------ drawing
func hurt_radius() -> float:
        return 44.0

func contact_radius() -> float:
        return 30.0

func bracket_size() -> Vector2:
        return Vector2(110.0, 150.0)

func observe_anchor() -> Vector2:
        return global_position + Vector2(0, -60.0)

func skin_set() -> String:
        return "bound_martyr"

func skin_fps() -> Dictionary:
        return {"p1": 1.2, "p1_attack": 5.0, "p2": 1.6, "p2_attack": 6.0,
                "p3": 2.0, "p3_attack": 6.0, "death": 1.0}

func skin_facing() -> int:
        return facing

func skin_pose() -> String:
        if state == DYING or state == DEAD:
                return "death"
        var base := "p%d" % phase
        match state:
                ATTACK, DASHING, LEAP_WINDUP, LEAPING:
                        return base + "_attack"
                _:
                        return base

func _sync_skin(delta: float) -> void:
        super(delta)
        if _skin:
                # phases visibly alter the light he carries
                match phase:
                        2:
                                _skin.self_modulate = Color(1.08, 1.0, 0.88, 1.0)
                        3:
                                _skin.self_modulate = Color(0.9, 0.86, 1.1, 1.0)
                        _:
                                _skin.self_modulate = Color(1, 1, 1, 1)

func _draw_body() -> void:
        var dying_k := clampf((state_t - 3.0) / 5.0, 0.0, 1.0) if state == DYING else 0.0
        var alpha := 1.0 - dying_k
        var painted := _skin != null and not GameState.debug_no_sprites
        var lean := 0.0
        if state == WINDUP:
                lean = -10.0 * facing * clampf(state_t / _windup_time(), 0.0, 1.0)
        if state == DASHING:
                lean = 14.0 * dash_dir
        # shadow — the ground under a colossus
        draw_colored_polygon(_ellipse(Vector2(0, 2), 42.0, 8.0), Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.4 * alpha))
        if painted:
                # the body is painted artwork; the world-bound chains remain
                # drawn (they physically run to the pillars and snap as he dies)
                var chain_col := Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.75 * alpha)
                var chains_alive := 3 - chain_breaks
                if chains_alive > 0:
                        for side in [-1, 1]:
                                var broken: bool = chain_breaks > 0 and int(side) == 1
                                var end_x: float = (float(side) * 300.0) if not broken else (float(side) * 60.0)
                                draw_line(Vector2(side * 26.0 + lean, -60.0), Vector2(end_x, -60.0 + (40.0 if broken else 0.0)), E0.ASH, 3.0)
                _draw_overlays(alpha, lean)
                return
        var col := E0.CHARCOAL
        # legs — colossal, bent under the weight of usefulness
        var stance := sin(anim_t * 1.2) * 2.0
        draw_line(Vector2(-14 + stance, -44), Vector2(-22, 0), col, 9.0)
        draw_line(Vector2(14 - stance, -44), Vector2(22, 0), col, 9.0)
        # torso
        var torso := PackedVector2Array([
                Vector2(-24 + lean, -44), Vector2(24 + lean, -44),
                Vector2(30 + lean * 1.3, -96), Vector2(-30 + lean * 1.3, -96),
        ])
        draw_colored_polygon(torso, Color(col.r, col.g, col.b, alpha))
        # the suffering shows: crimson seams
        for i in 3:
                var sy := -52.0 - i * 16.0
                draw_line(Vector2(-16 + lean, sy), Vector2(14 + lean, sy - 4.0), Color(E0.BLOOD.r, E0.BLOOD.g, E0.BLOOD.b, (0.35 + 0.15 * phase) * alpha), 2.0)
        # chains wrap the torso; they break as he dies
        var chain_col := Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.75 * alpha)
        var chains_alive := 3 - chain_breaks
        for i in 3:
                if i >= chains_alive:
                        continue
                var cy := -50.0 - i * 15.0
                for k in 5:
                        draw_circle(Vector2(-20.0 + k * 10.0 + lean, cy + sin(k * 1.5) * 3.0), 3.0, chain_col)
        # chains run off to the pillars
        if chains_alive > 0:
                for side in [-1, 1]:
                        var broken: bool = chain_breaks > 0 and int(side) == 1
                        var end_x: float = (float(side) * 300.0) if not broken else (float(side) * 60.0)
                        draw_line(Vector2(side * 26.0 + lean, -60.0), Vector2(end_x, -60.0 + (40.0 if broken else 0.0)), E0.ASH, 3.0)
        # head: hooded, bowed
        draw_circle(Vector2(lean * 1.6, -104), 13.0, Color(col.r, col.g, col.b, alpha))
        draw_rect(Rect2(lean * 1.6 - 6.0, -108, 12, 8), Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, alpha))
        # halo of the design — gold, cracked
        var halo_a := 0.5 if phase < 3 else 0.25
        draw_arc(Vector2(lean * 1.6, -108), 20.0, PI * 0.9, PI * 2.1, 16, Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, halo_a * alpha), 2.0)
        # the censer flail arm
        var arm_from := Vector2(facing * 26.0 + lean, -80.0)
        var swing := 0.0
        if state == WINDUP:
                swing = -0.9 * clampf(state_t / _windup_time(), 0.0, 1.0)
        elif state == ATTACK:
                swing = 0.9 * clampf(state_t / 0.25, 0.0, 1.0)
        elif state == DASH_WINDUP or state == DASHING:
                swing = -0.4
        elif state == LEAP_WINDUP or state == LEAPING:
                swing = 1.4
        var arm_to := arm_from + Vector2(facing * 40.0, 10.0).rotated(swing)
        draw_line(arm_from, arm_to, Color(col.r, col.g, col.b, alpha), 7.0)
        # censer ball on a short chain
        var ball := arm_to + (Vector2(facing * 30.0, 26.0).rotated(swing * 1.3))
        draw_line(arm_to, ball, E0.ASH, 3.0)
        draw_circle(ball, 11.0, Color(E0.GOLD.r * 0.7, E0.GOLD.g * 0.7, E0.GOLD.b * 0.7, alpha))
        var ember := 0.4 + 0.3 * sin(anim_t * 6.0)
        draw_circle(ball, 5.0, Color(E0.CRIMSON.r, E0.CRIMSON.g, E0.CRIMSON.b, ember * alpha))
        _draw_overlays(alpha, lean)

func _draw_overlays(alpha: float, lean: float) -> void:
        ## gameplay-critical overlays shared by painted and procedural bodies.
        # belief shield shimmer
        if shielded():
                var shield_a := 0.10 + 0.06 * sin(anim_t * 3.0)
                draw_circle(Vector2(lean * 0.5, -60.0), 78.0, Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, shield_a))
                draw_arc(Vector2(lean * 0.5, -60.0), 78.0, 0, TAU, 24, Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, shield_a * 2.0), 1.5)
        # fervor walls (phase 2)
        if phase == 2 and not state in [DYING, DEAD]:
                _draw_fervor()
        # windup telegraphs
        if state == WINDUP:
                _draw_telegraph()
        if state == DASH_WINDUP:
                draw_line(Vector2(dash_dir * 40.0, -30.0), Vector2(dash_dir * 400.0, -30.0),
                        Color(E0.CRIMSON.r, E0.CRIMSON.g, E0.CRIMSON.b, 0.22 + 0.2 * sin(anim_t * 20.0)), 3.0)
        if state == LEAP_WINDUP:
                draw_circle(leap_target - global_position, 110.0, Color(E0.CRIMSON.r, E0.CRIMSON.g, E0.CRIMSON.b, 0.10))
                draw_arc(leap_target - global_position, 110.0, 0, TAU, 28, Color(E0.CRIMSON.r, E0.CRIMSON.g, E0.CRIMSON.b, 0.5), 2.0)
        # dying: coming apart into ash
        var dying_k := clampf((state_t - 3.0) / 5.0, 0.0, 1.0) if state == DYING else 0.0
        if dying_k > 0.0:
                for i in 12:
                        var seed_a := float(i) * 2.399
                        var p := Vector2(cos(seed_a) * 30.0, -60.0 - dying_k * 20.0 + sin(seed_a) * 24.0)
                        draw_circle(p + Vector2(sin(anim_t * 2.0 + seed_a) * 6.0 * dying_k, -dying_k * 30.0), 2.0,
                                Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, (1.0 - dying_k) * 0.5))

func _draw_telegraph() -> void:
        var k := clampf(state_t / _windup_time(), 0.0, 1.0)
        var col := Color(E0.CRIMSON.r, E0.CRIMSON.g, E0.CRIMSON.b, 0.15 + 0.25 * k)
        match attack_pattern:
                0:
                        # low band along the ground
                        draw_rect(Rect2(Vector2(facing * 20.0, -18.0), Vector2(facing * 170.0, 18.0)), col)
                1:
                        # high band — roll under
                        draw_rect(Rect2(Vector2(facing * 20.0, -120.0), Vector2(facing * 170.0, 74.0)), col)
                2:
                        draw_arc(Vector2(0, -40), 150.0, 0, TAU, 28, col, 3.0)

func _draw_fervor() -> void:
        # walls of believed fire closing in
        for side_x in [fervor_l, fervor_r]:
                var local: float = float(side_x) - global_position.x
                for i in 10:
                        var t := float(i) / 9.0
                        var fy := -t * 300.0
                        var flick := 0.3 + 0.3 * sin(anim_t * 9.0 + t * 12.0 + side_x)
                        draw_line(Vector2(local, fy), Vector2(local, fy - 30.0), Color(E0.CRIMSON.r, E0.CRIMSON.g, E0.CRIMSON.b, flick * 0.5), 6.0)
                        draw_line(Vector2(local, fy), Vector2(local, fy - 30.0), Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, flick * 0.2), 2.0)

func _ellipse(center: Vector2, rx: float, ry: float) -> PackedVector2Array:
        var pts := PackedVector2Array()
        for i in 12:
                var a := TAU * i / 12.0
                pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
        return pts

func _draw_death() -> void:
        # final dissolution — the monument remains (spawned by Game)
        var t := death_t
        if t < 1.0:
                _draw_body()
        else:
                var alpha := clampf(1.0 - (t - 1.0) * 1.2, 0.0, 1.0)
                draw_circle(Vector2(0, -60.0), 40.0 * (1.0 - t * 0.2), Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, alpha * 0.2))
