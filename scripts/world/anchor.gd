## Anchor — a save shrine. Prayer and checkpoint in one gesture: kneel, the
## cyan vein pulses, the world is written. First communion restores +12
## consistency (THE DESIGN does not reassure the deeply inconsistent).
class_name Anchor
extends EntityNode

var communed := false
var pulse_t := 0.0
var saving := false
var _art: Texture2D = null

func setup_anchor(p_instance: String) -> void:
        setup("ANCHOR", p_instance, "anchor")
        extra["anchor_y"] = 30.0
        extra["br_w"] = 52.0
        extra["br_h"] = 66.0

func _ready() -> void:
        super()
        if ResourceLoader.exists("res://art/props/anchor.png"):
                _art = load("res://art/props/anchor.png")

func _refresh_prompt() -> void:
        prompt = "COMMUNE AT THE ANCHOR"

func interact(game) -> void:
        if saving:
                return
        saving = true
        pulse_t = 0.0
        AudioManager.play_sfx("sfx_shrine", -2.0)
        var anchor_id := instance_key
        var restored := GameState.anchor_communion(anchor_id)
        var ok: bool = game.save_at_anchor(self)
        if ok:
                EventBus.anchor_used.emit(anchor_id, GameState.current_room)
                if restored > 0:
                        game.system_message("ANCHOR ACCEPTED — CONSISTENCY +%d." % restored)
                        communed = true
                elif GameState.consistency < 60:
                        game.system_message("ANCHOR ACCEPTED. RESTORATION WITHHELD — RECORD TOO UNSTABLE.")
                else:
                        game.system_message("ANCHOR ACCEPTED. THE RECORD IS WRITTEN.")
        queue_redraw()
        saving = false

func _process(delta: float) -> void:
        anim_t += delta
        queue_redraw()

func _draw() -> void:
        var glow := 0.5 + 0.35 * sin(anim_t * 1.6)
        var vein := Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, glow)
        if _art != null and not GameState.debug_no_sprites:
                # the painted reliquary shrine; the system vein still pulses
                var aw := float(_art.get_width())
                var ah := float(_art.get_height())
                var h := 112.0
                var w := aw * h / ah
                draw_texture_rect(_art, Rect2(-w * 0.5, -h, w, h), false)
                draw_line(Vector2(w * 0.32, -6), Vector2(w * 0.44, -30), vein, 1.5)
                draw_line(Vector2(w * 0.44, -30), Vector2(w * 0.36, -52), vein, 1.5)
                draw_circle(Vector2(w * 0.36, -52), 2.2, vein)
                draw_circle(Vector2(0, -40), 34.0, Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.05 * glow))
                return
        # kneeling marker with a bowl of ash and a thin cyan vein
        var stone := E0.DIRTY_STONE
        draw_rect(Rect2(-24, -8, 48, 8), E0.ASH)
        # kneeling silhouette
        draw_colored_polygon(PackedVector2Array([
                Vector2(-10, -6), Vector2(10, -6), Vector2(12, -34), Vector2(4, -44),
                Vector2(-6, -42), Vector2(-13, -30),
        ]), stone)
        draw_circle(Vector2(2, -48), 7.0, stone)
        draw_rect(Rect2(-3, -50, 8, 6), E0.VOID)
        # the bowl
        draw_circle(Vector2(-16, -12), 9.0, stone.darkened(0.15))
        draw_circle(Vector2(-16, -14), 6.5, E0.PARCH.darkened(0.4))
        # the vein of system light
        draw_line(Vector2(14, -6), Vector2(20, -26), vein, 1.5)
        draw_line(Vector2(20, -26), Vector2(15, -44), vein, 1.5)
        draw_circle(Vector2(15, -44), 2.2, vein)
        draw_circle(Vector2(0, -26), 30.0, Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.05 * glow))
