## Door — blocking doors with real modification responses.
## Modes: "lock" (DOOR_029 — locked=false opens it), "accounts" (DOOR_114 —
## reconciling the contradiction opens it), "toll" (gate opens when the toll
## machine is BROKEN), "gate" (opens on a flag).
class_name Door
extends EntityNode

var open := false
var open_t := 0.0
var _body: StaticBody2D
var _body_shape: CollisionShape2D
var _w := 54.0
var _h := 150.0
var _art: Texture2D = null

func setup_door(p_entity_key: String, p_instance: String, mode: String, size: Vector2) -> void:
        setup(p_entity_key, p_instance, "door")
        extra["mode"] = mode
        extra["door_w"] = size.x
        extra["door_h"] = size.y
        _w = size.x
        _h = size.y
        extra["anchor_y"] = size.y * 0.5
        extra["br_w"] = size.x + 18.0
        extra["br_h"] = size.y + 10.0

func _ready() -> void:
        super()
        if ResourceLoader.exists("res://art/props/door.png"):
                _art = load("res://art/props/door.png")
        _body = StaticBody2D.new()
        _body.collision_layer = E0.L_WORLD
        _body.collision_mask = 0
        var shape := CollisionShape2D.new()
        var rect := RectangleShape2D.new()
        rect.size = Vector2(_w, _h)
        shape.shape = rect
        shape.position = Vector2(0, -_h * 0.5)
        _body.add_child(shape)
        _body_shape = shape
        add_child(_body)
        _refresh_prompt()

func _refresh_prompt() -> void:
        prompt = "OPEN " + data.display

func interact(game) -> void:
        if open:
                game.system_message(data.display + " IS OPEN.")
                return
        match String(extra["mode"]):
                "lock":
                        if bool(data.properties.get("locked", {}).get("value", true)):
                                AudioManager.play_sfx("sfx_door_locked", -4.0)
                                game.system_message("SEALED. THE PLAQUE INSISTS IT OPENS FOR NO ONE. READ IT WITH [TAB].")
                        else:
                                _open(game)
                "accounts":
                        if data.state == "RECONCILED":
                                _open(game)
                        else:
                                AudioManager.play_sfx("sfx_door_locked", -4.0)
                                game.system_message("THE DOOR IS DISPUTED WITH ITSELF. PLAQUE: ZERO. RECORD: 14,207. RECONCILE IT WITH [TAB].")
                "toll":
                        AudioManager.play_sfx("sfx_door_locked", -4.0)
                        game.system_message("TOLL GATE. THE MACHINE COLLECTS. IT HAS FORGOTTEN WHY. [ROLL] PAST IT, OR SETTLE THE ACCOUNT.")
                "gate":
                        var flag: String = extra.get("flag", "")
                        if GameState.has_flag(flag) or (flag == "boss_defeated" and GameState.boss_defeated):
                                _open(game)
                        else:
                                AudioManager.play_sfx("sfx_door_locked", -6.0)
                                game.system_message("THE GATE IS HELD BY SOMETHING THAT IS NOT A LOCK.")

func on_modified(prop_name: String, _old: Variant, _new: Variant) -> void:
        # Real world response — the door actually opens.
        match String(extra["mode"]):
                "lock":
                        if prop_name == "locked" and not bool(data.properties["locked"]["value"]):
                                _open(null)
                "accounts":
                        if prop_name == "accounts" and String(_new) == "RECONCILED":
                                data.set_state("RECONCILED")
                                _open(null)
        queue_redraw()

func try_open_from_flag() -> void:
        _open(null)

func _open(game) -> void:
        if open:
                return
        open = true
        data.set_state("OPEN")
        _body_shape.set_deferred("disabled", true)
        AudioManager.play_sfx("sfx_door_open", -2.0)
        if game:
                game.system_message("ACK. THE DOOR OPENS.")
        var tween := create_tween()
        tween.tween_property(self, "open_t", 1.0, 0.9)
        if game:
                FX.shake(3.0, 0.3)

func _process(delta: float) -> void:
        super(delta)
        if open and open_t < 1.0:
                queue_redraw()

func _draw_art_door() -> void:
        ## The manufactured iron ritual door — painted art on a stone frame.
        var frame := E0.DIRTY_STONE
        # chunky stone reveal around the slab
        draw_rect(Rect2(-_w * 0.5 - 8, -_h - 6, _w + 16, 10), frame)
        draw_rect(Rect2(-_w * 0.5 - 8, -10, _w + 16, 10), frame)
        draw_rect(Rect2(-_w * 0.5 - 8, -_h - 6, 10, _h + 6), frame)
        draw_rect(Rect2(_w * 0.5 - 2, -_h - 6, 10, _h + 6), frame)
        # the slab slides up into the frame when open — bottom slice remains
        var slide := open_t * (_h - 14.0)
        var slab_h := _h - 8.0 - slide
        var full_h := _h + 2.0
        if slab_h > 2.0:
                var aw := float(_art.get_width())
                var ah := float(_art.get_height())
                var frac := slab_h / full_h
                var src := Rect2(0.0, ah * (1.0 - frac), aw, ah * frac)
                var dst := Rect2(-_w * 0.5, -8.0 - slab_h, _w, slab_h)
                draw_texture_rect_region(_art, dst, src)
                if String(extra["mode"]) == "lock" and not open:
                        # the seal stays readable in every presentation
                        draw_rect(Rect2(-9, -_h * 0.62, 18, 18), E0.BLOOD)
                        draw_rect(Rect2(-5, -_h * 0.62 + 4, 10, 10), E0.ASH)
                if String(extra["mode"]) == "toll":
                        draw_rect(Rect2(-8, -60.0, 16, 5), E0.VOID)
                        draw_rect(Rect2(-5, -58.0, 10, 2), Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.5))
        if open and open_t < 1.0:
                for i in 3:
                        var t := fmod(anim_t * 2.0 + i * 0.33, 1.0)
                        draw_circle(Vector2(-_w * 0.3 + i * _w * 0.3, -8.0 - t * 20.0), 1.2, Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.3 * (1.0 - t)))

func _draw() -> void:
        if _art != null and not GameState.debug_no_sprites:
                _draw_art_door()
                return
        var frame := E0.DIRTY_STONE
        draw_rect(Rect2(-_w * 0.5 - 8, -_h - 6, _w + 16, 10), frame)
        draw_rect(Rect2(-_w * 0.5 - 8, -10, _w + 16, 10), frame)
        draw_rect(Rect2(-_w * 0.5 - 8, -_h - 6, 10, _h + 6), frame)
        draw_rect(Rect2(_w * 0.5 - 2, -_h - 6, 10, _h + 6), frame)
        # the slab slides up into the frame when open
        var slide := open_t * (_h - 14.0)
        var slab_h := _h - 8.0 - slide
        if slab_h > 2.0:
                var col := E0.ASH
                if String(extra["mode"]) == "accounts" and not open:
                        col = E0.VIOLET.darkened(0.2)
                elif String(extra["mode"]) == "toll":
                        col = E0.ASH
                draw_rect(Rect2(-_w * 0.5, -8.0 - slab_h, _w, slab_h), col)
                # rivets + a toll slot
                for i in int(maxi(2, int(slab_h / 30.0))):
                        draw_circle(Vector2(-_w * 0.5 + 8, -20.0 - i * 30.0), 2.0, E0.PARCH.darkened(0.45))
                        draw_circle(Vector2(_w * 0.5 - 8, -20.0 - i * 30.0), 2.0, E0.PARCH.darkened(0.45))
                if String(extra["mode"]) == "toll":
                        draw_rect(Rect2(-8, -60.0, 16, 5), E0.VOID)
                        draw_rect(Rect2(-5, -58.0, 10, 2), Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.5))
                if String(extra["mode"]) == "lock" and not open:
                        # seal glyph
                        draw_rect(Rect2(-9, -_h * 0.62, 18, 18), E0.BLOOD)
                        draw_rect(Rect2(-5, -_h * 0.62 + 4, 10, 10), E0.ASH)
        if open and open_t < 1.0:
                # dust falling from the rising slab
                for i in 3:
                        var t := fmod(anim_t * 2.0 + i * 0.33, 1.0)
                        draw_circle(Vector2(-_w * 0.3 + i * _w * 0.3, -8.0 - t * 20.0), 1.2, Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.3 * (1.0 - t)))
