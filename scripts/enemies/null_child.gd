## NULL CHILDREN — outside classification. They drift through walls, touch
## like frost, and cannot be ended — their state was never filed. Terminate
## the classification through OBSERVE and they can finally disperse.
class_name NullChild
extends EnemyBase

var drift_phase := 0.0
var drift_speed := 55.0
var _deny_msg_shown := false

func setup_null(p_pos: Vector2) -> void:
        setup_enemy("NULL_CHILD", "NULL_%d" % [randi() % 700 + 300])
        hp = E0.NULL_HP
        max_hp = hp
        contact_damage = E0.NULL_DMG
        global_position = p_pos
        drift_phase = randf() * TAU

func _post_ready() -> void:
        # Outside classification: no collision with the world. It simply ignores it.
        collision_mask = 0
        drift_speed *= 1.0 + 0.15 * GameState.stage

func _act(delta: float) -> void:
        drift_phase += delta * 0.7
        var pp := _player_pos()
        var to_player := (pp + Vector2(0, -30.0)) - (global_position + Vector2(0, -30.0))
        var drift := Vector2(sin(drift_phase), cos(drift_phase * 0.8)) * 30.0
        var desired := (to_player.normalized() * drift_speed + drift).limit_length(drift_speed + 22.0)
        velocity = velocity.lerp(desired, 2.0 * delta)
        velocity.y += 100.0 * delta * (1.0 if global_position.y < pp.y - 60.0 else 0.0)

func take_hit(dmg: int, from_pos: Vector2, heavy: bool) -> void:
        # UNFILED things cannot be ended. Change the state first.
        if data.state == "UNFILED":
                AudioManager.play_sfx("sfx_ui_deny", -4.0)
                FX.tear_pulse(0.2)
                if not _deny_msg_shown:
                        _deny_msg_shown = true
                        var game := get_tree().get_first_node_in_group("game")
                        if game and game.has_method("start_dialogue"):
                                game.start_dialogue("null_tut")
                return
        super(dmg, from_pos, heavy)

func is_invulnerable() -> bool:
        return data.state == "UNFILED"

func _die() -> void:
        # Terminated: the record closes and the child finally disperses.
        data.set_state("TERMINATED")
        super()
        AudioManager.play_sfx("sfx_null_warp", -4.0)

func skin_set() -> String:
        return "null_children"

func skin_fps() -> Dictionary:
        return {"idle": 2.2}

func _sync_skin(delta: float) -> void:
        super(delta)
        # an unfiled thing does not persist properly — flicker like a bad record
        if _skin and not dead:
                var flicker := 0.55 + 0.45 * sin(anim_t * 11.0)
                var base_a := _skin.modulate.a
                _skin.modulate.a = clampf(0.45 + 0.4 * flicker, 0.1, 1.0) * base_a
                if fmod(anim_t, 1.7) < 0.1:
                        _skin.self_modulate = Color(0.62, 0.9, 0.9)
                else:
                        _skin.self_modulate = Color(1, 1, 1)

func _draw_body() -> void:
        # painted skin active: keep the filing-error glitch and terminate mark
        if _skin != null and not GameState.debug_no_sprites:
                var jitter := Vector2(randf_range(-1.5, 1.5), randf_range(-1.5, 1.5))
                if data.state != "UNFILED":
                        draw_line(jitter + Vector2(-8, -20), jitter + Vector2(8, -20), Color(E0.CRIMSON.r, E0.CRIMSON.g, E0.CRIMSON.b, 0.5), 1.0)
                if fmod(anim_t, 1.7) < 0.1:
                        draw_rect(Rect2(jitter + Vector2(1, -46), Vector2(14, 30)), Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.14))
                return
        # a small pale figure that does not persist properly
        var jitter := Vector2(randf_range(-1.5, 1.5), randf_range(-1.5, 1.5))
        var terminated := data.state != "UNFILED"
        var base_col := E0.BONE if not terminated else E0.PARCH.lerp(E0.CRIMSON, 0.4)
        var flicker := 0.55 + 0.45 * sin(anim_t * 11.0)
        var col := Color(base_col.r, base_col.g, base_col.b, 0.45 + 0.4 * flicker)
        if hurt_flash > 0.0:
                col = col.lerp(Color(0.9, 0.6, 0.5), hurt_flash / 0.18)
        var c := jitter
        # small robed body, floating: feet do not reach anything
        draw_colored_polygon(PackedVector2Array([
                c + Vector2(-6, -18), c + Vector2(6, -18), c + Vector2(7, -38), c + Vector2(-7, -38),
        ]), col)
        draw_circle(c + Vector2(0, -43), 6.0, col)
        # the face is a filing error: two gaps that do not align
        draw_rect(Rect2(c + Vector2(-3.5, -45), Vector2(2, 4)), E0.VOID)
        draw_rect(Rect2(c + Vector2(1.0, -44.5), Vector2(2, 3)), E0.VOID)
        # no shadow. the ground under it is unstated.
        if terminated:
                draw_line(c + Vector2(-8, -20), c + Vector2(8, -20), Color(E0.CRIMSON.r, E0.CRIMSON.g, E0.CRIMSON.b, 0.5), 1.0)
        # afterimage glitch
        if fmod(anim_t, 1.7) < 0.1 or terminated:
                draw_colored_polygon(PackedVector2Array([
                        c + Vector2(-6 + 7, -18), c + Vector2(6 + 7, -18), c + Vector2(7 + 7, -38), c + Vector2(-7 + 7, -38),
                ]), Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.18))
