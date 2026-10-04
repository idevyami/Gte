## Anchor — a save shrine. Prayer and checkpoint in one gesture: kneel, the
## cyan vein pulses, the world is written. First communion restores +12
## consistency (THE DESIGN does not reassure the deeply inconsistent).
class_name Anchor
extends EntityNode

var communed := false
var pulse_t := 0.0
var saving := false
var save_fx_t := -1.0        # >=0 while the communion ceremony plays
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
        save_fx_t = 0.0            # the ceremony: pulse rings + rising motes

func _process(delta: float) -> void:
        anim_t += delta
        if save_fx_t >= 0.0:
                save_fx_t += delta
                if save_fx_t > 1.6:
                        save_fx_t = -1.0
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
                _draw_save_ceremony()
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
        _draw_save_ceremony()

func _draw_save_ceremony() -> void:
        ## The world is WRITTEN: two golden pulse rings expand along the floor
        ## while record-glyph motes rise from the shrine and dissolve.
        if save_fx_t < 0.0:
                return
        var t := save_fx_t
        for i in 2:
                var k := clampf((t - i * 0.22) / 1.1, 0.0, 1.0)
                if k <= 0.0 or k >= 1.0:
                        continue
                var r := 14.0 + k * 120.0
                var a := 0.5 * (1.0 - k) * (1.0 - k)
                var col := Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, a)
                # the ring reads as a floor ripple: squashed ellipse
                var pts := PackedVector2Array()
                for s in 20:
                        var ang := TAU * s / 20.0
                        pts.append(Vector2(0, -4) + Vector2(cos(ang) * r, sin(ang) * r * 0.22))
                draw_colored_polygon(pts, Color(col.r, col.g, col.b, a * 0.25))
                draw_polyline(pts, col, 1.4)
        # rising glyph motes: tiny written records ascending from the bowl
        for i in 7:
                var seed_a := float(i) * 2.399
                var k := fmod(t * 0.55 + float(i) * 0.143, 1.0)
                var p := Vector2(cos(seed_a) * 9.0 - (14.0 if i % 2 == 0 else -10.0),
                                -10.0 - k * 74.0)
                p.x += sin(t * 2.2 + seed_a) * 4.0
                var a := 0.65 * sin(PI * k)
                var mote := Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, a)
                if i % 3 == 0:
                        mote = Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, a * 0.9)
                # a glyph reads as 2-3 short strokes, not a blob
                draw_line(p, p + Vector2(0, -3.0), mote, 1.0)
                draw_line(p + Vector2(0, -1.5), p + Vector2(2.0, -2.5), mote, 1.0)
                if i % 2 == 0:
                        draw_line(p + Vector2(0, -2.0), p + Vector2(-1.5, -3.0), mote, 1.0)
