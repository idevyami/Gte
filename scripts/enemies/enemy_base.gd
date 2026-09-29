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
        contact_cd = maxf(0.0, contact_cd - delta)
        if dead and death_t >= 0.0:
                death_t += delta
                if death_t > 0.9:
                        queue_free()
        if _skin:
                _sync_skin(delta)
        queue_redraw()

func _sync_skin(_delta: float) -> void:
        _skin.visible = not GameState.debug_no_sprites
        _skin.flip_h = skin_facing() < 0
        var m := Color(1.0, 1.0, 1.0, 1.0)
        if hurt_flash > 0.0:
                m = m.lerp(Color(1.0, 0.42, 0.36), (hurt_flash / 0.18) * 0.55)
        if dead and death_t >= 0.0:
                m.a = clampf(1.0 - death_t * 1.2, 0.0, 1.0)
        _skin.modulate = m
        _skin.pose(skin_pose())

func _physics_process(delta: float) -> void:
        if dead:
                return
        _act(delta)
        move_and_slide()

func _act(_delta: float) -> void:
        pass

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
func take_hit(dmg: int, from_pos: Vector2, _heavy: bool) -> void:
        if dead:
                return
        if is_invulnerable():
                AudioManager.play_sfx("sfx_ui_deny", -6.0)
                return
        hp = maxi(0, hp - dmg)
        hurt_flash = 0.18
        var dir := -1 if from_pos.x > global_position.x else 1
        velocity = Vector2(dir * 180.0, -120.0)
        FX.burst(global_position + Vector2(0, -26), "glitch" if data.type == "OUTSIDER" else "ash", 0.0, 9)
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
        velocity = Vector2.ZERO
        var outsider := data.type == "OUTSIDER"
        FX.burst(global_position + Vector2(0, -26), "glitch" if outsider else "ash", 0.0, 18)
        if not outsider:
                FX.burst(global_position + Vector2(0, -30), "dust", 0.0, 6)
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
        if hurt_flash > 0.0:
                _draw_hurt_overlay()

func _draw_body() -> void:
        pass

func _draw_hurt_overlay() -> void:
        var k := hurt_flash / 0.18
        draw_circle(Vector2(0, -26), 26.0, Color(0.9, 0.75, 0.6, 0.25 * k))

func _draw_death() -> void:
        var t := death_t
        var alpha := clampf(1.0 - t * 1.4, 0.0, 1.0)
        for i in 8:
                var a := TAU * i / 8.0
                var d := t * 60.0
                draw_circle(Vector2(cos(a) * d, -26.0 + sin(a) * d * 0.6), 2.4 * alpha, Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, alpha * 0.6))
