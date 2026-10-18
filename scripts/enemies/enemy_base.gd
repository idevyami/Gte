## EnemyBase — shared enemy body: EntityData registration (OBSERVE-able),
## hurtbox, contact damage, hurt flash, knockback, death ash.
class_name EnemyBase
extends CharacterBody2D

var data: EntityData
var instance_key := ""
var hp := 60
var max_hp := 60
var hurt_flash := 0.0
var dead := false
var death_t := -1.0
var aggro := false
var anim_t := 0.0
var contact_cd := 0.0
var contact_damage := 0
var telegraph_t := 0.0        # >0 while winding an attack — reads as a warning
var _death_anim_len := 0.0     # >0 when the skin carries a death performance
var _dissolved := false        # the ash scatter fires once, at the fade
var _gait_accum := 0.0         # WB-15: distance walked since the last print
var _trace_cache: Traces = null
var _hurtbox: Area2D
var _contact: Area2D
var _skin: SpriteSkin

func setup_enemy(entity_key: String, p_instance: String) -> void:
        instance_key = p_instance
        data = EntityDB.mint(entity_key, p_instance)

func _ready() -> void:
        collision_layer = E0.L_ENEMY
        collision_mask = E0.L_WORLD
        var body_shape := CollisionShape2D.new()
        var capsule := CapsuleShape2D.new()
        capsule.radius = 12.0
        capsule.height = 48.0
        body_shape.shape = capsule
        body_shape.position = Vector2(0, -24.0)
        add_child(body_shape)
        _hurtbox = Area2D.new()
        _hurtbox.collision_layer = E0.L_HURTBOX
        _hurtbox.collision_mask = 0
        var hs := CollisionShape2D.new()
        var hc := CircleShape2D.new()
        hc.radius = hurt_radius()
        hs.shape = hc
        _hurtbox.add_child(hs)
        _hurtbox.set_meta("hurt_owner", self)
        add_child(_hurtbox)
        _contact = Area2D.new()
        _contact.collision_layer = 0
        _contact.collision_mask = E0.L_PLAYER
        _contact.body_entered.connect(_on_contact)
        var cs := CollisionShape2D.new()
        var cc := CircleShape2D.new()
        cc.radius = contact_radius()
        cs.shape = cc
        _contact.add_child(cs)
        add_child(_contact)
        EntityDB.register(self)
        _attach_skin()
        _post_ready()

func _attach_skin() -> void:
        ## Painted artwork layer; the procedural _draw body remains fallback.
        var sset := skin_set()
        if sset == "":
                return
        var sk := SpriteSkin.new()
        if sk.setup(sset, skin_fps()):
                _skin = sk
                add_child(sk)
                z_index = 1   # node-drawn FX (telegraphs, motes) render above

func skin_set() -> String:
        return ""

func skin_fps() -> Dictionary:
        return {}

func skin_pose() -> String:
        return "idle"

func skin_facing() -> int:
        return 1

func _post_ready() -> void:
        pass

func _exit_tree() -> void:
        EntityDB.unregister(self)

func hurt_radius() -> float:
        return 22.0

func contact_radius() -> float:
        return 18.0

func _process(delta: float) -> void:
        anim_t += delta
        hurt_flash = maxf(0.0, hurt_flash - delta)
        telegraph_t = maxf(0.0, telegraph_t - delta)
        contact_cd = maxf(0.0, contact_cd - delta)
        if dead and death_t >= 0.0:
                death_t += delta
                # the corpse keeps its momentum: the collapse is physical,
                # it slides and falls like the body it was
                velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
                if not is_on_floor():
                        velocity.y += 1500.0 * delta
                else:
                        velocity.y = 0.0
                move_and_slide()
                # the ash scatter waits for the collapse to land its last
                # frame — the body finishes its fall BEFORE it scatters
                if _death_anim_len > 0.0 and not _dissolved \
                                and death_t >= _death_anim_len:
                        _dissolved = true
                        _scatter_ash()
                var hold := maxf(0.9, _death_anim_len + 0.32)
                if death_t > hold:
                        queue_free()
        if _skin:
                _sync_skin(delta)
        queue_redraw()

func _scatter_ash() -> void:
        # the dissolve: fine bone-dust first (the shape lets go gently), a
        # restrained ash follow — never a red smear over the fallen body
        var outsider := data.type == "OUTSIDER"
        if outsider:
                FX.burst(global_position + Vector2(0, -12), "glitch", 0.0, 16)
        else:
                FX.burst(global_position + Vector2(0, -10), "dust", 0.0, 9)
                FX.burst(global_position + Vector2(0, -14), "ash", 0.0, 9)

func _sync_skin(_delta: float) -> void:
        _skin.visible = not GameState.debug_no_sprites
        _skin.flip_h = skin_facing() < 0
        # WB-21 THE CENSER'S EDGE: the self-lift starts from the body's own
        # light answer (the vessel's WB-17 law generalized) — the hurt flash
        # and death fade still own their frames on top of it
        var m := skin_lift()
        if hurt_flash > 0.0:
                m = m.lerp(Color(1.0, 0.5, 0.42), (hurt_flash / 0.26) * 0.85)
        if dead and death_t >= 0.0:
                if _death_anim_len > 0.0:
                        # SOLID through the collapse — the body performs its
                        # fall — then a slow dissolve once the ash scatters
                        # (the shape holds; it does not smear away)
                        var over := death_t - _death_anim_len
                        if over > 0.0:
                                m.a = clampf(1.0 - over / 0.26, 0.0, 1.0)
                else:
                        m.a = clampf(1.0 - death_t * 1.2, 0.0, 1.0)
        _skin.modulate = m
        if dead and _death_anim_len > 0.0:
                _skin.pose("death")
                return
        if hurt_flash > 0.0 and _skin.has_anim("hurt"):
                _skin.pose("hurt")
                return
        _skin.pose(skin_pose())

func _physics_process(delta: float) -> void:
        if dead:
                return          # corpse physics live in _process (death path)
        _act(delta)
        move_and_slide()
        _passage(delta)

func _act(_delta: float) -> void:
        pass

func skin_lift() -> Color:
        ## WB-21: the body's own answer to its light — the identity lift
        ## leaves every other creature exactly as it was; the believer
        ## overrides (the robe answers its censer, warm).
        return Color(1.0, 1.0, 1.0, 1.0)

# ------------------------------------------------------------- the passage

func gait_key() -> String:
        ## THE OTHERS' PASSAGE (WB-15): this creature's entry in the floor's
        ## memory (see Traces.GAITS). The DEFAULT is empty — the world is
        ## not obliged to remember everything, only what its fiction
        ## demands: the null children drift through walls (the floor never
        ## meets them), the correction is paperwork (it files past, it
        ## does not walk). The censor does not override this — it does not
        ## write at all; its passage ERASES (see Censor._process).
        return ""

func _trace_layer() -> Traces:
        ## The room's trace canvas — walked from the parents once, cached.
        if _trace_cache != null:
                return _trace_cache
        var node := get_parent()
        while node != null:
                if node is Game:
                        _trace_cache = node.traces
                        return _trace_cache
                node = node.get_parent()
        return null

func _passage(delta: float) -> void:
        ## The floor records its own creatures: each stride stamps the
        ## room's material with this body's gait. The enemy's origin sits
        ## at its feet, so the print lands a hair into the walking band.
        var key := gait_key()
        if key == "":
                return
        if not is_on_floor() or absf(velocity.x) < 40.0:
                return
        _gait_accum += absf(velocity.x) * delta
        var stride := float(Traces.GAITS.get(key, {}).get("stride", 30.0))
        if _gait_accum < stride:
                return
        _gait_accum = 0.0
        var tr := _trace_layer()
        if tr != null:
                tr.stamp_foot(global_position + Vector2(0.0, 4.0),
                        1.0 if velocity.x > 0.0 else -1.0, 1.0, key)

func _on_contact(body: Node2D) -> void:
        if dead or body == null or not body is Player:
                return
        if contact_cd > 0.0:
                return
        if not _contact_damages():
                return
        contact_cd = 0.8
        body.take_damage(contact_damage, global_position)

func _contact_damages() -> bool:
        return true

# ------------------------------------------------------------------ combat
func take_hit(dmg: int, from_pos: Vector2, _heavy: bool, style := 0) -> void:
        if dead:
                return
        if is_invulnerable():
                AudioManager.play_sfx("sfx_ui_deny", -6.0)
                return
        hp = maxi(0, hp - dmg)
        # WB-18: the hurt read was too quiet to read in motion — the flash
        # lasts longer, burns whiter, and the body is pushed harder
        hurt_flash = 0.26
        var dir := -1 if from_pos.x > global_position.x else 1
        velocity = Vector2(dir * 230.0, -150.0)
        # the wound card: a bright directional read at the contact point,
        # facing the way the blow pushes
        FX.impact(global_position + Vector2(-dir * 14.0, -26.0), dir, _heavy, style)
        FX.burst(global_position + Vector2(0, -26), "glitch" if data.type == "OUTSIDER" else "ash", 0.0, 11)
        _on_hurt()
        if hp <= 0:
                _die()

func is_invulnerable() -> bool:
        return false

func _on_hurt() -> void:
        pass

func _die() -> void:
        dead = true
        death_t = 0.0
        GameState.stats["dissipated"] += 1
        var outsider := data.type == "OUTSIDER"
        # THE ENDING'S RECORD (WB-16): the floor keeps the ending. The fall
        # is written in the walker's own weight, and its last strides
        # FREEZE mid-path — the walk ends here, and the record keeps where
        # it stopped. What never walked (an empty gait — the drifters, the
        # paperwork) leaves nothing: the floor cannot hold what it never met.
        var tr := _trace_layer()
        if tr != null:
                var gk := gait_key()
                if gk != "":
                        # the fall lies IN the walking band, deeper than any
                        # sole — a body's mass lands mid-band, where it lay
                        tr.stamp_fall(global_position + Vector2(0.0, 40.0),
                                1.0 if velocity.x >= 0.0 else -1.0,
                                float(Traces.GAITS.get(gk, {}).get("weight", 1.0)), gk)
                        tr.freeze_strides(gk)
        # the death PERFORMANCE: if the skin carries a death animation the
        # body plays its collapse whole (stun -> buckle -> down) and the
        # ash waits for it; without one, the old immediate scatter stands
        _death_anim_len = 0.0
        _dissolved = false
        if _skin and _skin.has_anim("death") and not GameState.debug_no_sprites:
                _death_anim_len = _skin.anim_duration("death")
        if _death_anim_len <= 0.0:
                _dissolved = true
                _scatter_ash()
        AudioManager.play_sfx("sfx_null_warp" if outsider else "sfx_death", -8.0)

func is_dead() -> bool:
        return dead

func observe_anchor() -> Vector2:
        return global_position + Vector2(0, -30.0)

func bracket_size() -> Vector2:
        return Vector2(40.0, 64.0)

# shared: blink teleport at low consistency (S4+)
func maybe_blink(distance_to_player: float) -> bool:
        if GameState.stage < 4 or distance_to_player < 200.0:
                return false
        if randf() < 0.006:
                var dir := signf(_player_pos().x - global_position.x)
                global_position += Vector2(dir * 70.0, 0.0)
                AudioManager.play_sfx("sfx_null_warp", -10.0)
                FX.tear_pulse(0.35)
                return true
        return false

func _player_pos() -> Vector2:
        var p := get_tree().get_first_node_in_group("player")
        if p:
                return p.global_position
        return Vector2.ZERO

func _draw() -> void:
        if dead:
                _draw_death()
                return
        _draw_body()
        if telegraph_t > 0.0:
                _draw_telegraph()
        if hurt_flash > 0.0:
                _draw_hurt_overlay()

func _draw_body() -> void:
        pass

func _draw_hurt_overlay() -> void:
        var k := hurt_flash / 0.26
        draw_circle(Vector2(0, -26), 26.0, Color(0.9, 0.75, 0.6, 0.25 * k))

func _draw_telegraph() -> void:
        ## The wind-up warning: a rising warm seal at the attack's height —
        ## honest signalling, the horror is the world, not cheap hits.
        var k := clampf(telegraph_t / 0.5, 0.0, 1.0)
        var r := lerpf(36.0, 20.0, 1.0 - k)          # tightens as it winds
        var pulse := fmod(anim_t * 12.0, 1.0)
        var a := 0.55 + 0.35 * (1.0 - k) * pulse
        # bright hot gold — dim gold dies on the dark fog
        var hot := Color(1.0, 0.84, 0.46)
        # soft backing glow so the ring reads on dark fog
        draw_circle(Vector2(0, -26), r * 0.8, Color(hot.r, hot.g, hot.b, a * 0.20))
        draw_arc(Vector2(0, -26), r, 0.0, TAU, 22, Color(hot.r, hot.g, hot.b, a), 3.5)
        draw_arc(Vector2(0, -26), r * 0.62, 0.0, TAU, 16,
                Color(1.0, 0.93, 0.72, a * 0.8), 1.8)
        # rising warning ticks at the cardinal points
        for i in 4:
                var ang := TAU * i / 4.0 - PI * 0.5
                var p0 := Vector2(0, -26) + Vector2(cos(ang), sin(ang)) * (r + 4.0)
                var p1 := p0 + Vector2(cos(ang), sin(ang)) * (5.0 + (1.0 - k) * 6.0)
                draw_line(p0, p1, Color(1.0, 0.93, 0.72, a * 0.9), 2.0)

func _draw_death() -> void:
        var t := death_t
        var alpha := clampf(1.0 - t * 1.4, 0.0, 1.0)
        for i in 8:
                var a := TAU * i / 8.0
                var d := t * 60.0
                draw_circle(Vector2(cos(a) * d, -26.0 + sin(a) * d * 0.6), 2.4 * alpha, Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, alpha * 0.6))
