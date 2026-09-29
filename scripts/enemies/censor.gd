## THE CENSOR — the system's answer to your edits. It does not chase. It
## arrives. It cannot be fought — only survived. Its touch corrects: 30 HP
## and −4 consistency. Spawns at stage 4+, despawns after ~25 seconds.
class_name Censor
extends Node2D

var data: EntityData
var instance_key := "THE_CENSOR"
var life_t := 0.0
var anim_t := 0.0
var contact_cd := 0.0
var speed := 120.0
var _skin: SpriteSkin

func _ready() -> void:
        data = EntityDB.mint("CENSOR", instance_key)
        speed = E0.CENSOR_SPEED_S4 if GameState.stage == 4 else E0.CENSOR_SPEED_S5
        AudioManager.play_sfx("sfx_censor", 2.0)
        FX.tear_pulse(1.0)
        EntityDB.register(self)
        var sk := SpriteSkin.new()
        if sk.setup("censor", {"idle": 2.0}):
                _skin = sk
                add_child(sk)
                z_index = 1

func _exit_tree() -> void:
        EntityDB.unregister(self)
        if GameState.censor_active == self:
                GameState.censor_active = null

func _process(delta: float) -> void:
        anim_t += delta
        life_t += delta
        contact_cd = maxf(0.0, contact_cd - delta)
        if _skin:
                _skin.visible = not GameState.debug_no_sprites
                # the censor is not quite inside the world's visual rules
                var flick := 0.85 + 0.15 * sin(anim_t * 17.0)
                _skin.modulate = Color(flick, flick, flick, 1.0)
                _skin.pose("idle")
        var player := get_tree().get_first_node_in_group("player") as Player
        if player and player.hp > 0:
                var to_p := player.global_position - global_position
                global_position += to_p.normalized() * speed * delta * (0.85 + 0.3 * sin(anim_t * 0.6))
                if to_p.length() < 26.0 and contact_cd <= 0.0:
                        contact_cd = 1.2
                        player.take_damage(E0.CENSOR_DMG, global_position)
                        GameState.spend(E0.CENSOR_TOUCH_DRAIN, "correction")
                        FX.tear_pulse(1.2)
                        FX.shake(9.0, 0.4)
        if life_t > 25.0:
                _depart()

func _depart() -> void:
        var tween := create_tween()
        tween.tween_property(self, "modulate:a", 0.0, 0.8)
        tween.tween_callback(queue_free)
        set_process(false)

func observe_anchor() -> Vector2:
        return global_position + Vector2(0, -50.0)

func bracket_size() -> Vector2:
        return Vector2(46.0, 120.0)

func _draw() -> void:
        # a redaction given a body — painted art when available, geometry otherwise
        var flick := 0.85 + 0.15 * sin(anim_t * 17.0)
        var painted := _skin != null and not GameState.debug_no_sprites
        if not painted:
                var col := Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, flick)
                # the bar itself
                draw_rect(Rect2(Vector2(-11, -110), Vector2(22, 110)), col)
                draw_rect(Rect2(Vector2(-11, -110), Vector2(22, 110)), Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.9), false, 2.0)
                # the strike-through — it crosses out what it touches
                draw_rect(Rect2(Vector2(-22, -66 + sin(anim_t * 2.4) * 6.0), Vector2(44, 7)), Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.95))
        else:
                # cyan glitch afterimages where the correction has already passed
                for i in 3:
                        var off := Vector2((i + 1) * -6.0 * sin(anim_t * 2.0), (i + 1) * 3.0)
                        draw_rect(Rect2(Vector2(-11, -110) + off, Vector2(22, 110)), Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.05))
        # scanning line — always drawn, always wrong
        var scan_y := -110.0 + fmod(anim_t * 60.0, 110.0)
        draw_rect(Rect2(Vector2(-11, scan_y), Vector2(22, 2)), Color(E0.CRIMSON.r, E0.CRIMSON.g, E0.CRIMSON.b, 0.5))
        # where it stands, the ground is already corrected
        draw_rect(Rect2(Vector2(-16, 0), Vector2(32, 2)), Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.6))
