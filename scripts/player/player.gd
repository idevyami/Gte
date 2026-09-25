## ENTITY_000_818 — the player vessel. Weighted movement, coyote/buffer jumps,
## 3-hit chain with hitstop, roll with i-frames, crawl-sized shape while rolling.
class_name Player
extends CharacterBody2D

var hp: int = E0.P_MAX_HP
var max_hp: int = E0.P_MAX_HP
var facing := 1
var input_locked := false
var controllable := true          # false during death / transitions

# movement state
var _coyote := 0.0
var _buffer := 0.0
var _rolling := false
var _roll_t := 0.0
var _roll_cd := 0.0
var _roll_dir := 1

# combat state
var _attack_cd := 0.0
var _attack_idx := -1             # -1 idle, else chain index 0..2
var _attack_phase := 0.0          # progress of current swing
var _chain_expiry := 0.0
var _hit_pending := false
var _hit_done := false
var _iframes := 0.0
var _step_accum := 0.0
var _hurt_flash := 0.0
# input buffers: captured on idle frames, consumed by physics
var _jump_press := 0.0
var _attack_press := 0.0
var _roll_press := 0.0

var rig: PlayerRig
var sprite: PlayerSprite
var interact_pose_t := 0.0
var _shape: CollisionShape2D
var _stand_extents := Vector2(11, 24)
var _roll_extents := Vector2(11, 9)

func _ready() -> void:
        collision_layer = E0.L_PLAYER
        collision_mask = E0.L_WORLD
        z_index = 5
        _shape = CollisionShape2D.new()
        var capsule := CapsuleShape2D.new()
        capsule.radius = _stand_extents.x
        capsule.height = _stand_extents.y * 2.0
        _shape.shape = capsule
        add_child(_shape)
        rig = PlayerRig.new()
        rig.player = self
        add_child(rig)
        # painted artwork when available; the procedural rig stays as fallback
        sprite = PlayerSprite.new()
        if sprite.setup("player", {
                "idle": 1.3, "walk": 8.0, "jump": 4.0, "fall": 4.0,
                "attack1": 9.0, "attack2": 9.0, "attack3": 9.0,
                "hurt": 5.0, "death": 1.6, "interact": 3.0,
                "observe": 2.0, "roll": 9.0,
        }):
                sprite.attach(self)
                add_child(sprite)
                rig.visible = false
        else:
                sprite = null
        EventBus.player_health_changed.emit(hp, max_hp)

func _physics_process(delta: float) -> void:
        if not controllable:
                move_and_slide()
                rig.sync_state(delta)
                if sprite:
                        sprite.sync_state(delta)
                return
        _tick_timers(delta)
        _apply_gravity(delta)
        _handle_movement(delta)
        _handle_jump()
        _handle_roll(delta)
        _handle_attack(delta)
        move_and_slide()
        rig.sync_state(delta)
        if sprite:
                sprite.sync_state(delta)

func play_interact() -> void:
        ## Called by Game when the interact key lands on something.
        interact_pose_t = 0.5

func _tick_timers(delta: float) -> void:
        _coyote = maxf(0.0, _coyote - delta)
        _buffer = maxf(0.0, _buffer - delta)
        _roll_cd = maxf(0.0, _roll_cd - delta)
        _attack_cd = maxf(0.0, _attack_cd - delta)
        _iframes = maxf(0.0, _iframes - delta)
        _hurt_flash = maxf(0.0, _hurt_flash - delta)
        if is_on_floor():
                _coyote = E0.P_COYOTE
        # footsteps
        if is_on_floor() and absf(velocity.x) > 40.0 and not _rolling:
                _step_accum += absf(velocity.x) * delta
                if _step_accum > 34.0:
                        _step_accum = 0.0
                        AudioManager.play_sfx("sfx_step", -10.0)

func _apply_gravity(delta: float) -> void:
        if not is_on_floor():
                var g := E0.P_FALL_GRAVITY if velocity.y > 0.0 else E0.P_GRAVITY
                velocity.y = minf(E0.P_MAX_FALL, velocity.y + g * delta)

func _handle_movement(delta: float) -> void:
        if _rolling:
                velocity.x = _roll_dir * E0.P_ROLL_SPEED
                return
        var dir := 0.0
        if not input_locked:
                if Input.is_action_pressed("move_left"):
                        dir -= 1.0
                if Input.is_action_pressed("move_right"):
                        dir += 1.0
        var control := 1.0 if is_on_floor() else E0.P_AIR_CONTROL
        if dir != 0.0:
                velocity.x = move_toward(velocity.x, dir * E0.P_MAX_SPEED, E0.P_ACCEL * control * delta)
                if not input_locked:
                        facing = 1 if dir > 0 else -1
        else:
                velocity.x = move_toward(velocity.x, 0.0, E0.P_FRICTION * control * delta)

func _handle_jump() -> void:
        if input_locked or _rolling:
                return
        if _jump_press > 0.0:
                _buffer = E0.P_BUFFER
                _jump_press = 0.0
        if _buffer > 0.0 and _coyote > 0.0:
                velocity.y = E0.P_JUMP
                _buffer = 0.0
                _coyote = 0.0
                AudioManager.play_sfx("sfx_jump", -8.0)
        # let go early = shorter jump
        if Input.is_action_just_released("jump") and velocity.y < 0.0:
                velocity.y *= 0.55

func _handle_roll(delta: float) -> void:
        _roll_t = maxf(0.0, _roll_t - delta)
        if _rolling:
                if _roll_t <= 0.0:
                        _rolling = false
                        _set_shape(_stand_extents)
                return
        if input_locked:
                return
        if _roll_press > 0.0 and is_on_floor() and _roll_cd <= 0.0 and _attack_idx == -1:
                _rolling = true
                _roll_press = 0.0
                _roll_t = E0.P_ROLL_TIME
                _roll_cd = E0.P_ROLL_CD
                _roll_dir = facing if absf(velocity.x) < 20.0 else (1 if velocity.x > 0 else -1)
                _iframes = maxf(_iframes, E0.P_ROLL_TIME + 0.06)
                _set_shape(_roll_extents)
                AudioManager.play_sfx("sfx_roll", -8.0)

func _set_shape(extents: Vector2) -> void:
        var capsule := _shape.shape as CapsuleShape2D
        capsule.radius = extents.x
        capsule.height = extents.y * 2.0
        _shape.position.y = _stand_extents.y - extents.y

func _handle_attack(delta: float) -> void:
        if _attack_idx != -1:
                _attack_phase += delta
                # impact lands 80ms into the swing
                if _hit_pending and _attack_phase >= 0.08:
                        _hit_pending = false
                        _do_hit(_attack_idx)
                if _attack_phase >= 0.22:
                        _attack_idx = -1
                        _attack_phase = 0.0
                return
        if input_locked or _rolling or not is_on_floor():
                return
        if _attack_press > 0.0 and _attack_cd <= 0.0:
                if _chain_expiry > 0.0 and _chain_expiry_idx < 2:
                        _attack_idx = _chain_expiry_idx + 1
                else:
                        _attack_idx = 0
                _attack_phase = 0.0
                _attack_press = 0.0
                _attack_cd = E0.P_ATTACK_CD
                _hit_pending = true
                _hit_done = false
                _chain_expiry_idx = _attack_idx
                _chain_expiry = E0.P_CHAIN_WINDOW
                rig.play_swing(_attack_idx, facing)
                AudioManager.play_sfx(["sfx_swing_a", "sfx_swing_b", "sfx_swing_c"][_attack_idx], -6.0)

var _chain_expiry_idx := 0

func _tick_chain(delta: float) -> void:
        _chain_expiry = maxf(0.0, _chain_expiry - delta)

func _process(delta: float) -> void:
        _tick_chain(delta)
        interact_pose_t = maxf(0.0, interact_pose_t - delta)
        if _attack_idx >= 0 and sprite:
                queue_redraw()   # weapon trail follows the painted swing
        # input buffers: captured on idle frames, consumed by physics — inputs
        # are never swallowed by a missed physics tick
        if Input.is_action_just_pressed("jump"):
                _jump_press = E0.P_BUFFER
        if Input.is_action_just_pressed("attack"):
                _attack_press = 0.14
        if Input.is_action_just_pressed("roll"):
                _roll_press = 0.14
        _jump_press = maxf(0.0, _jump_press - delta)
        _attack_press = maxf(0.0, _attack_press - delta)
        _roll_press = maxf(0.0, _roll_press - delta)

func _do_hit(chain_idx: int) -> void:
        var space := get_world_2d().direct_space_state
        var params := PhysicsShapeQueryParameters2D.new()
        var circle := CircleShape2D.new()
        circle.radius = 46.0
        params.shape = circle
        params.transform = Transform2D(0.0, global_position + Vector2(facing * 36.0, -6.0))
        params.collision_mask = E0.L_HURTBOX
        params.collide_with_areas = true
        params.collide_with_bodies = false
        var hits := space.intersect_shape(params, 8)
        var dmg: int = E0.P_CHAIN[chain_idx]
        var any := false
        for hit in hits:
                var collider = hit.get("collider")
                var target = collider
                if collider and collider.has_meta("hurt_owner"):
                        target = collider.get_meta("hurt_owner")
                if target and target.has_method("take_hit"):
                        target.take_hit(dmg, global_position, chain_idx == 2)
                        any = true
        if any:
                FX.hitstop(0.05 if chain_idx < 2 else 0.09)
                FX.shake(2.0 if chain_idx < 2 else 4.0, 0.12)
                AudioManager.play_sfx("sfx_hit_light" if chain_idx < 2 else "sfx_hit_heavy", -4.0)

# ------------------------------------------------------------------ damage
func take_damage(dmg: int, from_pos: Vector2) -> void:
        if _iframes > 0.0 or hp <= 0:
                return
        hp = maxi(0, hp - dmg)
        _iframes = E0.P_HURT_IFRAMES
        _hurt_flash = 0.3
        AudioManager.play_sfx("sfx_hurt", -3.0)
        FX.shake(5.0, 0.25)
        var dir := -1 if from_pos.x > global_position.x else 1
        velocity = Vector2(dir * 240.0, -260.0)
        EventBus.player_health_changed.emit(hp, max_hp)
        if hp <= 0:
                die()

func die() -> void:
        if hp > 0:
                return
        controllable = false
        EventBus.player_died.emit()
        AudioManager.play_sfx("sfx_death", -2.0)
        AudioManager.play_death_sting()
        rig.play_death()
        FX.shake(6.0, 0.5)

func heal(amount: int) -> void:
        hp = mini(max_hp, hp + amount)
        EventBus.player_health_changed.emit(hp, max_hp)

func is_rolling() -> bool:
        return _rolling

func has_iframes() -> bool:
        return _iframes > 0.0

func current_chain() -> int:
        return _attack_idx

# ------------------------------------------------------------------ trail
func _draw() -> void:
        ## Painted-mode weapon trail: a fading arc for the active swing only.
        ## (The procedural rig draws its own trails when sprites are off.)
        if sprite == null or GameState.debug_no_sprites or _attack_idx < 0:
                return
        var t := clampf(_attack_phase / 0.22, 0.0, 1.0)
        if t <= 0.02:
                return
        var f := facing
        var idx := _attack_idx
        var center := Vector2(0, -26)
        var radius := 38.0 + 9.0 * idx
        var span := 150.0
        var base_deg := -40.0
        if idx == 1:
                base_deg = -170.0
        elif idx == 2:
                base_deg = -130.0
                span = 190.0
                radius += 6.0
        var prog := clampf(t * 1.45, 0.0, 1.0)
        var head_deg := base_deg + span * prog
        var fade: float = clampf(1.0 - t * 0.85, 0.0, 1.0)
        for k in 3:
                var end_deg := head_deg - k * 9.0
                var start_deg := end_deg - (20.0 - k * 5.0)
                if start_deg < base_deg:
                        start_deg = base_deg
                var col := Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.34 * fade * (1.0 - k * 0.28))
                if k == 0:
                        col = col.lerp(Color(E0.BONE.r, E0.BONE.g, E0.BONE.b), 0.35)
                var a0 := deg_to_rad(start_deg)
                var a1 := deg_to_rad(end_deg)
                if f < 0:
                        a0 = deg_to_rad(180.0 - start_deg)
                        a1 = deg_to_rad(180.0 - end_deg)
                draw_arc(center, radius, a0, a1, 10, col, 3.0 - k * 0.8)
