## THE HOLLOW — the absence of identity, walking. Patrols; stalks; telegraphs
## a lunge you are meant to read. At low consistency it blinks toward you.
class_name Hollow
extends EnemyBase

enum { PATROL, STALK, TELEGRAPH, LUNGE, RECOVER }

var state := PATROL
var state_t := 0.0
var patrol_from := 0.0
var patrol_to := 0.0
var facing := 1
var lunge_dir := 1

func setup_hollow(p_pos: Vector2, p_patrol: Vector2) -> void:
        setup_enemy("HOLLOW", "HOLLOW_%d" % [randi() % 900 + 100])
        hp = E0.HOLLOW_HP
        max_hp = hp
        contact_damage = E0.HOLLOW_DMG
        global_position = p_pos
        patrol_from = p_patrol.x
        patrol_to = p_patrol.y
        data.properties["aggression"]["value"] = "DORMANT"

func _act(delta: float) -> void:
        state_t += delta
        var pp := _player_pos()
        var dist := absf(pp.x - global_position.x)
        var player := get_tree().get_first_node_in_group("player") as Player
        var player_alive: bool = player != null and player.hp > 0
        match state:
                PATROL:
                        aggro = false
                        data.properties["aggression"]["value"] = "DORMANT"
                        var speed := 90.0
                        velocity.x = facing * speed
                        if global_position.x < patrol_from:
                                facing = 1
                        elif global_position.x > patrol_to:
                                facing = -1
                        if dist < 260.0 and player_alive:
                                state = STALK
                                state_t = 0.0
                                data.properties["aggression"]["value"] = "STALKING"
                STALK:
                        aggro = true
                        data.properties["aggression"]["value"] = "STALKING"
                        velocity.x = signf(pp.x - global_position.x) * 150.0
                        facing = 1 if pp.x > global_position.x else -1
                        maybe_blink(dist)
                        if dist < 90.0 and state_t > 0.4:
                                state = TELEGRAPH
                                state_t = 0.0
                                velocity.x = 0.0
                                AudioManager.play_sfx("sfx_ui_move", -8.0)
                        elif dist > 420.0:
                                state = PATROL
                                state_t = 0.0
                TELEGRAPH:
                        velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
                        if state_t > 0.55:
                                state = LUNGE
                                state_t = 0.0
                                lunge_dir = 1 if pp.x > global_position.x else -1
                                facing = lunge_dir
                                AudioManager.play_sfx("sfx_swing_c", -8.0)
                LUNGE:
                        velocity.x = lunge_dir * 340.0
                        if state_t > 0.34:
                                state = RECOVER
                                state_t = 0.0
                RECOVER:
                        velocity.x = move_toward(velocity.x, 0.0, 500.0 * delta)
                        if state_t > 0.6:
                                state = STALK
                                state_t = 0.0
        velocity.y += 1500.0 * delta if not is_on_floor() else 0.0

func _contact_damages() -> bool:
        return state == LUNGE

func _on_hurt() -> void:
        if state in [PATROL, STALK]:
                state = STALK
                state_t = 0.0

func skin_set() -> String:
        return "hollow"

func skin_fps() -> Dictionary:
        return {"idle": 2.0, "telegraph": 3.0, "lunge": 6.0}

func skin_facing() -> int:
        return facing

func skin_pose() -> String:
        match state:
                TELEGRAPH:
                        return "telegraph"
                LUNGE:
                        return "lunge"
                _:
                        return "idle"

func _draw_body() -> void:
        # painted skin active: keep only the readable crimson telegraph
        if _skin != null and not GameState.debug_no_sprites:
                if state == TELEGRAPH:
                        var kk := clampf(state_t / 0.55, 0.0, 1.0)
                        draw_line(Vector2(facing * 20.0, -30.0), Vector2(facing * (20.0 + 90.0 * kk), -30.0),
                                Color(E0.CRIMSON.r, E0.CRIMSON.g, E0.CRIMSON.b, 0.25 + 0.3 * kk), 2.0)
                return
        # tall gaunt figure of ash; the chest is a hollow
        var lean := 0.0
        if state == TELEGRAPH:
                lean = -8.0 * facing * clampf(state_t / 0.55, 0.0, 1.0)
        if state == LUNGE:
                lean = 10.0 * facing
        var col := E0.PARCH.darkened(0.25)
        if state == TELEGRAPH:
                var k := 0.5 + 0.5 * sin(state_t * 30.0)
                col = col.lerp(E0.CRIMSON, k * 0.7)
        if hurt_flash > 0.0:
                col = col.lerp(Color(0.9, 0.8, 0.7), hurt_flash / 0.18)
        # legs
        var stride := sin(anim_t * 8.0) * 5.0 if absf(velocity.x) > 20.0 else 0.0
        draw_line(Vector2(-3 + stride, -26), Vector2(-5, 0), col, 3.5)
        draw_line(Vector2(3 - stride, -26), Vector2(5, 0), col, 3.5)
        # torso: a drawn-out, wrong proportion
        var torso := PackedVector2Array([
                Vector2(-7 + lean, -26), Vector2(7 + lean, -26),
                Vector2(9 + lean * 1.6, -64), Vector2(-9 + lean * 1.6, -64),
        ])
        draw_colored_polygon(torso, Color(col.r, col.g, col.b, 0.92))
        # the hollow chest cavity
        draw_circle(Vector2(lean * 1.6, -48), 6.5, E0.VOID)
        draw_arc(Vector2(lean * 1.6, -48), 6.5, 0, TAU, 10, col.darkened(0.3), 1.0)
        # long arms hang past the knees
        draw_line(Vector2(-8 + lean, -60), Vector2(-11 + lean, -18), col.darkened(0.1), 3.0)
        draw_line(Vector2(8 + lean, -60), Vector2(11 + lean, -18), col.darkened(0.1), 3.0)
        # head: smooth, featureless, tilted
        draw_circle(Vector2(lean * 2.0, -70), 8.0, col)
        draw_circle(Vector2(lean * 2.0 + facing * 3.0, -69), 2.2, E0.VOID)
        # shadow
        draw_colored_polygon(_ellipse(Vector2(0, 1), 15.0, 3.5), Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.35))
        if state == TELEGRAPH:
                # the read: a crimson flash line before the lunge
                var k := clampf(state_t / 0.55, 0.0, 1.0)
                draw_line(Vector2(facing * 20.0, -30.0), Vector2(facing * (20.0 + 90.0 * k), -30.0),
                        Color(E0.CRIMSON.r, E0.CRIMSON.g, E0.CRIMSON.b, 0.25 + 0.3 * k), 2.0)

func _ellipse(center: Vector2, rx: float, ry: float) -> PackedVector2Array:
        var pts := PackedVector2Array()
        for i in 10:
                var a := TAU * i / 10.0
                pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
        return pts

func _draw_death() -> void:
        super()
        if death_t < 0.4:
                var alpha := clampf(1.0 - death_t * 2.5, 0.0, 1.0)
                draw_colored_polygon(PackedVector2Array([
                        Vector2(-7, -26), Vector2(7, -26), Vector2(9, -64), Vector2(-9, -64),
                ]), Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, alpha * 0.5))
                draw_circle(Vector2(0, -70), 8.0, Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, alpha * 0.5))
