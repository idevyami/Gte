## THE CENSOR — the system's answer to your edits. It does not chase. It
## arrives. It cannot be fought — only survived. Its touch corrects: 30 HP
## and −4 consistency. Spawns at stage 4+, despawns after ~25 seconds.
## WB-5: full performance — it UNFURLS into place (arrive), hovers on a
## 6-frame bob, LEANS into its correction (reach), and sheds the records
## it has already redacted as torn pages drifting behind it.
class_name Censor
extends Node2D

var data: EntityData
var instance_key := "THE_CENSOR"
var life_t := 0.0
var anim_t := 0.0
var contact_cd := 0.0
var speed := 120.0
var _skin: SpriteSkin
var _pose := "arrive"        # arrive -> idle -> (reach) -> idle
var _reach_t := 0.0
var _trail: Array = []         # recent positions — the shed pages ride it
var _trail_t := 0.0

func _ready() -> void:
        data = EntityDB.mint("CENSOR", instance_key)
        speed = E0.CENSOR_SPEED_S4 if GameState.stage == 4 else E0.CENSOR_SPEED_S5
        AudioManager.play_sfx("sfx_censor", 2.0)
        FX.tear_pulse(1.0)
        EntityDB.register(self)
        var sk := SpriteSkin.new()
        if sk.setup("censor", {"idle": 5.0, "arrive": 9.0, "reach": 11.0}):
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
                # pose machine: unfurl on arrival, hover, lean on touch.
                # (the arrive check requires the anim to have STARTED — a
                # fresh AnimatedSprite reports finished=true before its
                # first play, which used to skip the unfurl entirely)
                if _pose == "reach":
                        _reach_t -= delta
                        if _reach_t <= 0.0:
                                _pose = "idle"
                elif _pose == "arrive":
                        if _skin.animation == "arrive" and _skin.anim_finished():
                                _pose = "idle"
                _skin.pose(_pose)
        # the shed-record trail: where it has passed, pages fall out of it
        _trail_t -= delta
        if _trail_t <= 0.0:
                _trail_t = 0.09
                _trail.append({"p": global_position + Vector2(0, -46 + randf_range(-14.0, 14.0)),
                        "t": 0.0, "r": randf() * TAU, "spin": randf_range(-2.4, 2.4)})
                if _trail.size() > 7:
                        _trail.pop_front()
        for s in _trail:
                s["t"] = float(s["t"]) + delta
        var player := get_tree().get_first_node_in_group("player") as Player
        if player and player.hp > 0:
                var to_p := player.global_position - global_position
                global_position += to_p.normalized() * speed * delta * (0.85 + 0.3 * sin(anim_t * 0.6))
                if to_p.length() < 26.0 and contact_cd <= 0.0:
                        contact_cd = 1.2
                        _pose = "reach"
                        _reach_t = 0.3
                        player.take_damage(E0.CENSOR_DMG, global_position)
                        GameState.spend(E0.CENSOR_TOUCH_DRAIN, "correction")
                        FX.tear_pulse(1.2)
                        FX.shake(9.0, 0.4)
        if life_t > 25.0:
                _depart()
        queue_redraw()

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
        # the shed pages FIRST — they fall behind everything else it draws
        # (trail points are recorded in GLOBAL space; _draw is local)
        for s in _trail:
                var t: float = s["t"]
                if t > 1.4:
                        continue
                var k := t / 1.4
                var pp: Vector2 = (s["p"] as Vector2) - global_position + Vector2(sin(t * 3.0 + float(s["r"])) * 6.0, t * t * 22.0)
                var rot := float(s["r"]) + float(s["spin"]) * t
                var c := cos(rot)
                var sn := sin(rot)
                var hw := 4.6
                var hh := 6.4
                var pts := PackedVector2Array([
                        pp + Vector2(-hw * c + hh * sn, -hw * sn - hh * c),
                        pp + Vector2(hw * c + hh * sn, hw * sn - hh * c),
                        pp + Vector2(hw * c - hh * sn, hw * sn + hh * c),
                        pp + Vector2(-hw * c - hh * sn, -hw * sn + hh * c),
                ])
                draw_colored_polygon(pts, Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.42 * (1.0 - k)))
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
