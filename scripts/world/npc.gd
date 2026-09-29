## NPC — MEASURER OREN (the queue clerk) and THE PENITENT (who speaks only in
## contradictions and is never explained). Observable, interactable, drawn.
class_name NPC
extends EntityNode

var npc_id := "oren"
var _vanish_t := -1.0
var _appear_t := 1.0
var _skin: SpriteSkin

func setup_npc(p_npc: String, p_entity_key: String, p_instance: String, p_silent := false) -> void:
        npc_id = p_npc
        setup(p_entity_key, p_instance, "npc")
        extra["anchor_y"] = 40.0
        extra["br_w"] = 46.0
        extra["br_h"] = 70.0
        extra["silent"] = p_silent

func _ready() -> void:
        super()
        var sset := ""
        if npc_id == "penitent":
                sset = "penitent"
        elif npc_id == "oren":
                sset = "oren"
        if sset != "":
                var sk := SpriteSkin.new()
                if sk.setup(sset, {"idle": 1.5}):
                        _skin = sk
                        add_child(sk)
                        z_index = 1

func _refresh_prompt() -> void:
        prompt = "SPEAK" if npc_id == "oren" else "APPROACH"

func interact(game) -> void:
        match npc_id:
                "oren":
                        if GameState.stage >= 3 and GameState.fire_once("oren_aware"):
                                game.start_dialogue("oren_aware")
                        elif GameState.fire_once("oren_intro"):
                                game.start_dialogue("oren_intro")
                        else:
                                game.start_dialogue("oren_farewell")
                "penitent":
                        if extra.get("silent", false):
                                game.system_message("IT DOES NOT SPEAK. IT HAS ALREADY SAID EVERYTHING IT INTENDS TO.")
                        else:
                                game.start_dialogue("penitent")

func vanish() -> void:
        _vanish_t = 0.0

func _process(delta: float) -> void:
        anim_t += delta
        if _vanish_t >= 0.0:
                _vanish_t += delta
                if _vanish_t > 1.2:
                        visible_prop(false)
        if _skin:
                _skin.visible = not GameState.debug_no_sprites and is_visible_in_tree()
                var m := Color(1.0, 1.0, 1.0, 1.0)
                if npc_id == "penitent":
                        m.a = 0.75 + 0.2 * sin(anim_t * 0.8)
                        if _vanish_t >= 0.0:
                                m.a *= clampf(1.0 - _vanish_t / 1.2, 0.0, 1.0)
                        if fmod(anim_t, 3.0) < 0.12:
                                m = m.lerp(Color(0.62, 0.9, 0.9), 0.35)
                _skin.modulate = m
                _skin.pose("idle")
        if npc_id == "penitent":
                queue_redraw()

func _draw() -> void:
        if _skin != null and not GameState.debug_no_sprites:
                # painted art active — the ground mark under the penitent remains
                if npc_id == "penitent":
                        var vk := clampf(1.0 - _vanish_t / 1.2, 0.0, 1.0) if _vanish_t >= 0.0 else 1.0
                        draw_rect(Rect2(-10, -2, 20, 2), Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.4 * vk))
                return
        match npc_id:
                "oren":
                        _draw_oren()
                "penitent":
                        _draw_penitent()

func _draw_oren() -> void:
        # clerk-priest: tall robes, measuring chain, a stamping hand that never tires
        var robe := E0.VIOLET.darkened(0.35)
        draw_colored_polygon(PackedVector2Array([
                Vector2(-13, -2), Vector2(13, -2), Vector2(15, -50), Vector2(-15, -50),
        ]), robe)
        # stole of office
        draw_rect(Rect2(-4, -50, 8, 46), E0.GOLD.darkened(0.4))
        draw_circle(Vector2(0, -56), 8.0, robe.lightened(0.05))
        # the measuring lens over the face
        draw_circle(Vector2(3, -55), 4.5, Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.25))
        draw_arc(Vector2(3, -55), 4.5, 0, TAU, 12, Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.6), 1.0)
        # stamping arm: metronomic
        var stamp := absf(sin(anim_t * 2.0))
        draw_line(Vector2(12, -44), Vector2(24, -34 + stamp * 4.0), robe.lightened(0.08), 3.5)
        draw_rect(Rect2(22, -34 + stamp * 4.0, 8, 5), E0.GOLD.darkened(0.3))
        # the ledger on a stand
        draw_rect(Rect2(24, -30, 14, 8), E0.PARCH.darkened(0.4))

func _draw_penitent() -> void:
        # tall, ragged, wrong. white where others are dark. it does not quite persist.
        var a := 0.75 + 0.2 * sin(anim_t * 0.8)
        var vanish_k := 1.0
        if _vanish_t >= 0.0:
                vanish_k = clampf(1.0 - _vanish_t / 1.2, 0.0, 1.0)
        var col := Color(E0.BONE.r, E0.BONE.g, E0.BONE.b, a * vanish_k)
        # ragged shroud
        var pts := PackedVector2Array()
        var h := 92.0
        for i in 10:
                var x := -12.0 + 24.0 * i / 9.0
                var y := -h + (6.0 * sin(i * 2.7 + anim_t * 1.5))
                pts.append(Vector2(x, y))
        for i in 10:
                var x := 12.0 - 24.0 * i / 9.0
                var y := -4.0 + (5.0 * sin(i * 1.9 + anim_t * 1.2))
                pts.append(Vector2(x, y))
        draw_colored_polygon(pts, Color(col.r, col.g, col.b, 0.85 * vanish_k))
        # the hood is empty
        draw_circle(Vector2(0, -h + 4), 9.0, Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, vanish_k))
        draw_arc(Vector2(0, -h + 4), 9.0, PI, TAU, 10, Color(col.r, col.g, col.b, vanish_k), 1.5)
        # it flickers: afterimage
        var flick := fmod(anim_t, 3.0)
        if flick < 0.12:
                draw_colored_polygon(pts, Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.2))
        # no shadow — the ground under it is clean
        draw_rect(Rect2(-10, -2, 20, 2), Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.4 * vanish_k))
